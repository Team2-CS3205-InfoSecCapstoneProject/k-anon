require "sinatra/base"
require "sinatra/flash"

module Kanon
  class WebApp < Sinatra::Base

    set :server, :thin
    set :environment, :production
    set :logging, false
    set :sessions, :key_size => 32, :salt => SecureRandom.hex(32), :signed_salt => SecureRandom.hex(32)
    set :session_store, Rack::Session::EncryptedCookie
    set :app_file, __FILE__
    set :root, File.expand_path("#{File.dirname(__FILE__)}/../../")
    set :public_folder, proc { File.join(root, "public") }
    set :views, proc { File.join(root, "views") }
    set :run, proc { false }

    register Sinatra::Flash
    alias_method :h, :escape_html

    if (Kanon::Konstants.appEnvProd?)
      use Raven::Rack

      Raven.configure do |config|
        config.dsn = Kanon::Konstants.sentryReportLink
      end
      statsd = Datadog::Statsd.new       
    end

    helpers Kanon::AppHelper

    before do
      protect_from_request_forgery!
    end

    use Warden::Manager do |config|
      config.serialize_into_session{|user| user.sessionDuplicate}
      config.serialize_from_session{|sessionDuplicate| Kanon::Models::User.get(sessionDuplicate)}

      config.scope_defaults :default,
        strategies: [:password],
        action: '/auth/unauthenticated'
      config.failure_app = self
    end

    Warden::Manager.before_failure do |env,opts|
      request = Rack::Request.new(env)
      token = request.session[:csrf]
      env['REQUEST_METHOD'] = 'POST'
      env['HTTP_X_CSRF_TOKEN'] = token
      env.each do |key, value|
        env[key]['_method'] = 'post' if key == 'rack.request.form_hash'
      end
    end

    Warden::Strategies.add(:password) do
      def valid?
        params['user'] && params['user']['username'] && params['user']['password']
      end

      def authenticate!
        username = Sanitize.fragment(params['user']['username']).gsub(/[^0-9A-Za-z]/, '')
        password = Sanitize.fragment(params['user']['password'])
        payload  = {'researcher_username' => username}
        Raven.extra_context(usernameInput: username, helloworld: password)

        user = Kanon::Models::User.first(username: username)
        if user.nil?          
          resource = Kanon::WebAPI.restLogin(payload.to_json)
          if (resource.code == 200)
            researcher = JSON.parse(resource.body, :symbolize_names => true)
            if (researcher[:password].nil?)
              throw(:warden, message: "Please register for an account.")
            end
            session[:otpSecret] = researcher[:otpsecret]
            tempUser = Kanon::Models::User.new
            tempUser.password_hash = researcher[:password]
            if tempUser.authenticate(password)
              session[:sessionDuplicate] ||= SecureRandom.hex(64)
              newUser = Kanon::Models::User.new
              newUser.username = username
              newUser.password = password
              newUser.sessionDuplicate = session[:sessionDuplicate]
              newUser.getResearcherObject(newUser, username)
              newUser.save
              session[:username] = username
              success!(newUser)
            else
              throw(:warden, message: "The username and password combination is incorrect.")
            end
          end
        else
          env['warden'].raw_session.inspect
          env['warden'].logout(user.sessionDuplicate)
          session.clear
          user.destroy
          throw(:warden, message: "Only one session per user allowed. Please log in again.")
        end
      end
    end
    #End Warden Configuration

    get '/' do
      verbose("GET /", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      statsd.gauge('Kanon.Users.count_online', countOnlineUser) if checkProd?
      redirect '/kanon/auth/login'
    end

    get '/auth/login' do
      verbose("GET /auth/login", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      statsd.increment('Kanon.Login.page_views') if checkProd?
      if session[:login] == true
        redirect '/kanon/search'
      end
      erb :"auth/login", :layout => false
    end

    post '/auth/login' do
      verbose("POST /auth/login", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      env['warden'].authenticate!
      username = session[:username]

      otpCheck = Kanon::WebAPI.restCheckOTP(username)
      if otpCheck.body == "false"
        env['warden'].raw_session.inspect
        env['warden'].logout
        session[:otpUsername] = username
        redirect '/kanon/register/otp'
      else
        session[:login] = true
        redirect '/kanon/auth/otp'
      end
    end

    get '/auth/otp' do
      verbose("GET /auth/otp", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      env['warden'].authenticate!
      if session[:otpSecret].nil?
        redirect '/kanon/auth/logout'
      end
      erb :"auth/otp", :layout => false
    end

    post '/auth/otp' do
      verbose("POST /auth/otp", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      env['warden'].authenticate!
      otpcode  = Sanitize.fragment(params['user']['otp']).gsub(/[^0-9]/, '')
      Raven.extra_context(otpCodeInput: otpcode, username: session[:username])

      if session[:otpSecret].nil?
        redirect '/kanon/auth/logout'
      end
      totp = ROTP::TOTP.new(session[:otpSecret])
      if totp.verify(otpcode)
        session[:isOTP] = true
        session[:otpUsername] = nil
        session[:otpSecret] = nil
        flash.now[:success] = "Successfully logged in"
        statsd.increment('Kanon.Login.successful_login') if checkProd? 
        redirect '/kanon/search'
      else
        flash[:error] = "OTP Invalid"
        redirect '/kanon/auth/otp'
      end
    end

    get '/auth/logout' do
      verbose("GET /auth/logout", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      user = Kanon::Models::User.first(username: session[:username])
      if user.nil? 
        env['warden'].raw_session.inspect
        env['warden'].logout
        session.clear
        redirect '/kanon'
      end
      env['warden'].raw_session.inspect
      env['warden'].logout(user.sessionDuplicate)
      session[:login] = false
      if !session[:isOTP]
        flash[:error] = "Invalid OTP. Please log in"
        user.destroy
        session.clear
      elsif !session[:sessionDuplicate]
        flash[:error] = "Session Expired"
        session.clear
      else
        flash[:success] = "Logout Successfully"
        user.destroy
        session.clear
      end
      redirect '/kanon'
    end

    post '/auth/unauthenticated' do
      verbose("POST /auth/unauthenticated", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      session[:login] = false
      session[:return_to] = env['warden.options'][:attempted_path] if session[:return_to].nil?

      # Set the error and use a fallback if the message is not defined
      flash[:error] = env['warden.options'][:message] || "You must log in"
      redirect '/kanon/auth/login'
    end

    post '/register' do
      verbose("POST /register", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      firstname = Sanitize.fragment(params[:register][:firstname]).gsub(/[^0-9A-Za-z]/, '')
      lastname = Sanitize.fragment(params[:register][:lastname]).gsub(/[^0-9A-Za-z]/, '')
      username = Sanitize.fragment(params[:register][:username]).gsub(/[^0-9A-Za-z]/, '')
      password = Sanitize.fragment(params[:register][:password])
      confirmPassword = Sanitize.fragment(params[:register][:confirmPassword])
      captcha = params['g-recaptcha-response']
      Raven.extra_context(firstnameInput: firstname, lastnameInput: lastname, usernameInput: username)

      captchaAPIResponse = Kanon::WebAPI.googleCaptcha(captcha)
      googleRes = JSON.parse(captchaAPIResponse.body, :symbolize_names => true)
      if (!googleRes[:success])
        flash[:error] = "Captcha Error"
        redirect to ('/kanon/#signup')
      end
  
      verbose("Registering account with username: #{username}", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      if !registerCheck?(firstname, lastname, username, password, confirmPassword)
        redirect to ('/kanon/#signup')
      end
      passwordHash = BCrypt::Password.create(password, :cost => 12)
      payload = {'researcher_username' => username, 'password' => passwordHash, 
        'firstname' => firstname, 'lastname' => lastname}
      begin
        resource = Kanon::WebAPI.restRegister(payload.to_json)
        if resource.body == "Failed"    
          flash[:error] = "Username is used."
          redirect to ('/kanon/#signup')
        end
      rescue RestClient::Exceptions::OpenTimeout => e
        flash[:error] = "WebAPI is Down. Inform db gurus ASAP!"
        redirect to ('/kanon/#signup')
      end
      flash[:success] = "Successfully signed up!"
      session[:otpUsername] = username
      statsd.increment('Kanon.Registration.account_successful') if checkProd?
      redirect '/kanon/register/otp'
    end

    get '/register/otp' do
      verbose("GET /register/otp", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      username = session[:otpUsername]
      otpSecret = session[:otpSecret]
      if otpSecret.nil?
        otpSecret = ROTP::Base32.random_base32
        session[:otpSecret] = otpSecret
      end 
      if username.nil?
        flash[:error] = "Please Log In"
        redirect '/kanon/auth/login'
      end
      totp = ROTP::TOTP.new(otpSecret, issuer: "Kanon")
      otpURI = totp.provisioning_uri(username)
      qr = RQRCode::QRCode.new(otpURI)
      @image = qr.as_png(
          resize_gte_to: false,
          resize_exactly_to: false,
          fill: 'white',
          color: 'black',
          size: 120,
          border_modules: 4,
          module_px_size: 6,
          )
      erb :"register/otp", :layout => false
    end

    post '/register/otp' do
      verbose("POST /register/otp", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      totp = ROTP::TOTP.new(session[:otpSecret])
      otpCode = Sanitize.fragment(params[:otp][:number]).gsub(/[^0-9]/, '')
      if totp.verify(otpCode)
        totpsecret = session[:otpSecret]
        username = session[:otpUsername]
        payload = {'researcher_username' => username, 'otpsecret' => totpsecret}
        resource = Kanon::WebAPI.restConfigureOTP(payload.to_json)
        if resource.body == "Success"
          session.clear
          flash[:success] = "OTP for your account configured!"
          statsd.increment('Kanon.Registration.otp_successful') if checkProd?
          redirect '/kanon'
        else
          flash[:error] = "OTP Registration Failed"
          redirect '/kanon/register/otp'
        end
      else
        flash[:error] = "Re-enter OTP Code"
        redirect '/kanon/register/otp'
      end
    end

    get '/permission' do
      verbose("GET /permission", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      env['warden'].authenticate!
      check?(session[:username])
      statsd.increment('Kanon.Permission.page_views') if checkProd?

      isAdmin = Kanon::Models::User.first(username: session[:username]).isAdmin
      if isAdmin.nil?
        redirect '/kanon/auth/logout'
      end
      result = nil
      if !isAdmin
        # researcher: get researcher's existing request
        researcher_id = Kanon::Models::User.first(username: session[:username]).researcher_id
        begin
          resource = Kanon::WebAPI.restCategoryList(researcher_id)
          if resource.code == 200
            result = JSON.parse(resource.body)
            result = result["categories"]
          elsif resource.code == 204
          else
            verbose("Gotten #{resource.code} from cs3205-4.", Kanon::Logs::LogManager.VERBOSE_ERROR)
            status resource.code
          end
        rescue RestClient::Exceptions::OpenTimeout => e
          verbose("Response timed out for cs3205-4.", Kanon::Logs::LogManager.VERBOSE_FATAL)
          status 503
        end
      else
        # admin: get all existing request
        begin
          resource = Kanon::WebAPI.restCategoryListAll()
          if resource.code == 200
            result = JSON.parse(resource.body)
            result_return = []
            result.each do |item|
              item["categories"].each do |category|
                new_item = {}
                new_item["researcher_id"] = item["researcher_id"]
                new_item["researcher_username"] = item["researcher_username"]
                new_item["name"] = item["firstname"].to_s + ' ' + item["lastname"].to_s
                new_item["qualification"] = item["qualification"].to_s
                new_item["qualification_name"] = item["qualication_name"].to_s
                new_item["category_id"] = category["category_id"]
                new_item["category_name"] = category["category_name"]
                new_item["status"] = category["status"]
                result_return << new_item
              end
            end
            
            result = result_return
          elsif resource.code == 204
          else
            verbose("Gotten #{resource.code} from cs3205-4.", Kanon::Logs::LogManager.VERBOSE_ERROR)
            status resource.code
          end
        rescue RestClient::Exceptions::OpenTimeout => e
          verbose("Response timed out for cs3205-4.", Kanon::Logs::LogManager.VERBOSE_FATAL)
          status 503
        end
      end
      
      erb :"permission/view", :layout => true, :locals => {:isAdmin => isAdmin, :result => result}
    end

    post '/permission' do
      verbose("POST /permission", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      env['warden'].authenticate!
      check?(session[:username])

      isAdmin = Kanon::Models::User.first(username: session[:username]).isAdmin
      if isAdmin.nil?
        redirect '/kanon/auth/logout'
      end
      if !isAdmin
        flash[:error] = "Please log in as admin"
        redirect '/kanon/permission'
      end

      # Check if user selected at least 1 permission
      if !params["request"]
        flash[:error] = "No permission allocated"
        redirect '/kanon/permission'
      end

      # Loop through and request permission
      params["request"].each do |request, value|
        researcher_id, category_id = request.split(',')
        hash = {}
        hash["researcher_id"] = researcher_id
        hash["category_id"] = category_id
        payload = hash.to_json

        verbose("payload: #{payload}", Kanon::Logs::LogManager.VERBOSE_DEBUG)

        response = nil
        if params["action"] == "Approve"
          response = Kanon::WebAPI.restCategoryApprove(payload)
        else
          response = Kanon::WebAPI.restCategoryDecline(payload)
        end

        if response == "Failed"
          flash[:error] = "Permission allocation may have failed, please try again"
          verbose("Failed", Kanon::Logs::LogManager.VERBOSE_DEBUG)
          redirect '/kanon/permission'
        end
      end

      flash[:success] = "Successfully allocated permission"
      redirect '/kanon/permission'
    end

    get '/permission/request' do
      verbose("GET /permission/request", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      env['warden'].authenticate!
      check?(session[:username])

      # get list of categories
      result = nil
      begin
        resource = Kanon::WebAPI.restCategoryInfo()
        if resource.code == 200
          result = JSON.parse(resource.body)
        elsif resource.code == 204
        else
          verbose("Gotten #{resource.code} from cs3205-4.", Kanon::Logs::LogManager.VERBOSE_ERROR)
          status resource.code
        end
      rescue RestClient::Exceptions::OpenTimeout => e
        verbose("Response timed out for cs3205-4.", Kanon::Logs::LogManager.VERBOSE_FATAL)
        status 503
      end

      # get researcher's existing request
      researcher_id = Kanon::Models::User.first(username: session[:username]).researcher_id
      if researcher_id.nil?
        redirect '/kanon/auth/logout'
      end
      begin
        resource = Kanon::WebAPI.restCategoryList(researcher_id)
        if resource.code == 200
          requests = JSON.parse(resource.body)
          requests["categories"].each do |request|
            result.each do |item|
              if "#{request["category_id"]}" == "#{item["category_id"]}"
                item["status"] = request["status"]
              end
            end
          end
        elsif resource.code == 204
        else
          verbose("Gotten #{resource.code} from cs3205-4.", Kanon::Logs::LogManager.VERBOSE_ERROR)
          status resource.code
        end
      rescue RestClient::Exceptions::OpenTimeout => e
        verbose("Response timed out for cs3205-4.", Kanon::Logs::LogManager.VERBOSE_FATAL)
        status 503
      end

      erb :"permission/request", :layout => true, :locals => {:result => result}
    end

    post '/permission/request' do
      verbose("POST /permission/request", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      env['warden'].authenticate!
      check?(session[:username])

      researcher_id = Kanon::Models::User.first(username: session[:username]).researcher_id
      if researcher_id.nil?
        redirect '/kanon/auth/logout'
      end

      # Check if user selected at least 1 permission
      if !params["request"]
        flash[:error] = "No permission requested"
        redirect '/kanon/permission/request'
      end

      # Loop through and request permission
      params["request"].each do |category_id, value|
        hash = {}
        hash["researcher_id"] = researcher_id
        hash["category_id"] = category_id
        payload = hash.to_json

        verbose("payload: #{payload}", Kanon::Logs::LogManager.VERBOSE_DEBUG)

        response = Kanon::WebAPI.restCategoryRequest(payload)
        if response == "Failed"
          flash[:error] = "Request may have failed, please try again"
          verbose("Failed", Kanon::Logs::LogManager.VERBOSE_DEBUG)
          redirect '/kanon/permission/request'
        end
      end

      flash[:success] = "Successfully requested for new permission"
      redirect '/kanon/permission/request'
    end

    get '/search' do
      verbose("GET /search", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      env['warden'].authenticate!
      check?(session[:username])
      statsd.increment('Kanon.Search.page_views') if checkProd?
      statsd.gauge('Kanon.Users.online', countOnlineUser) if checkProd?
      Raven.extra_context(username: session[:username])
      if Kanon::Models::User.first(username: session[:username]).research_category.nil?
        redirect '/kanon/auth/logout'
      end
      researchCategories = Kanon::Models::User.first(username: session[:username]).research_category.split(",").map {|s| s.to_i }
      conditionsFilters = Array.new
      conditions = getPermittedSearchConditions(researchCategories)
      conditions.keys.each { |key|
        conditionHash = Hash.new
        conditionHash["id"] = nil
        conditionHash["isset"] = "1"
        conditionHash["key"] = key
        conditionHash["parent_id"] = nil
        conditionHash["type"] = "3"
        conditionHash["value"] = conditions[key]
        conditionsFilters.push(conditionHash)
      }

      nationalityFilters = prepareFormat(getNationalityFilters())
      ethnicityFilters = prepareFormat(getEthnicityFilters())

      filters = getSearchResultFilters()

      searchFilters = Array.new
      resultFilters = Array.new

      filters.each { |filter|
        if filter["type"] == "1" && filter["value"] != "conditions" && filter["value"] != "nationality" && filter["value"] != "ethnicity"
          searchFilters.push filter
        elsif filter["type"] == "1" && filter["value"] == "conditions"
          filter["children"] = conditionsFilters
          searchFilters.push filter
        elsif filter["type"] == "1" && filter["value"] == "nationality"
          filter["children"] = nationalityFilters
          searchFilters.push filter
        elsif filter["type"] == "1" && filter["value"] == "ethnicity"
          filter["children"] = ethnicityFilters
          searchFilters.push filter
        elsif filter["type"] == "2"
          resultFilters.push filter
        end
      }

      strip_ids! searchFilters, Proc.new { |k| k == "id" || k == "parent_id" }
      strip_ids! resultFilters, Proc.new { |k| k == "id" || k == "parent_id" }

      @searchFiltersJson = JSON.generate(searchFilters)
      @resultFiltersJson = JSON.generate(resultFilters)
      @hasPermissions = if conditions.length > 0 then true else false end
      
      erb :search, :layout => true
    end

    post '/search' do
      jsonParams = JSON.parse(request.body.read)
      verbose("POST /search, body: #{jsonParams}", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      env['warden'].authenticate!
      check?(session[:username])
      statsd.increment('Kanon.Search.submitted_searches') if checkProd?
      Raven.extra_context(username: session[:username], searchparams: jsonParams)

      searchParams = Hash.new
      jsonParams.each { |element|
          key = element.keys[0]
          value = element.values[0]
          unless searchParams.key?(key)
              searchParams[key] = Array.new
          end

          if key == 'ageRange'
            case value
            when '0-10'
            when '11-20'
            when '21-30'
            when '31-40'
            when '41-50'
            when '51-60'
            when '61-70'
            when '71-80'
            when '81-90'
            when '91-200'
            else redirect '/kanon/search'
            end
          end

          searchParams[key].push(value)
      }

      # filter by allowed category .. conditions before forwarding
      if Kanon::Models::User.first(username: session[:username]).research_category.nil?
        redirect '/kanon/auth/logout'
      end
      researchCategories = Kanon::Models::User.first(username: session[:username]).research_category.split(",").map {|s| s.to_i }
      conditions = searchParams["cid"]
      filteredConditions = filterConditions(researchCategories, conditions)
      searchParams["cid"] = filteredConditions unless filteredConditions.nil?

      # forward request to WebAPI
      payload = JSON.generate(searchParams)
      Raven.extra_context(payload: payload)

      # printing out json so we can copy and test manually
      verbose("Forwarding JSON object to cs3205-4 " + payload.to_s, Kanon::Logs::LogManager.VERBOSE_DEBUG)

      result = nil
      begin
        apiResponse = Kanon::WebAPI.restSearch(payload)

        if apiResponse.code == 200
          verbose("Gotten HTTP #{apiResponse.code} from cs3205-4.", Kanon::Logs::LogManager.VERBOSE_DEBUG)
          result = JSON.parse(apiResponse.body)
          
          # parsing of the results, k-anonimizing done here
          rows_retrieved = result.count
          Kanon::Anonymizer.new(result)
          rows_remaining = result.count
          verbose("Anonymizer returning #{rows_remaining} out of #{rows_retrieved} results", Kanon::Logs::LogManager.VERBOSE_DEBUG)

          columns = nil
          columns = result[0].keys unless result.count == 0
        else
          verbose("Gotten HTTP #{apiResponse.code} from cs3205-4.", Kanon::Logs::LogManager.VERBOSE_ERROR)
          status apiResponse.code
        end
      rescue RestClient::Exceptions::OpenTimeout => e
        verbose("Response timed out for cs3205-4.", Kanon::Logs::LogManager.VERBOSE_FATAL)
        status 503
      end
      
      content_type :json
      json_response = [
          "columns": columns,
          "results": result,
          "search_params": payload
        ].to_json
      return json_response
    end

    get '/heartdata/:id' do |id|
      env['warden'].authenticate!
      check?(session[:username])
      verbose("GET /heartdata/"+ id, Kanon::Logs::LogManager.VERBOSE_DEBUG)

      begin
          
        hash = {}
        hash["uid"] = id
        payload = hash.to_json

        apiResponse = Kanon::WebAPI.restHeart(payload)
        
        if apiResponse.code == 200
          verbose("Gotten HTTP #{apiResponse.code} from cs3205-4.", Kanon::Logs::LogManager.VERBOSE_DEBUG)
          result = JSON.parse(apiResponse.body)     
        else
          verbose("Gotten HTTP #{apiResponse.code} from cs3205-4.", Kanon::Logs::LogManager.VERBOSE_ERROR)
          status apiResponse.code
        end
      rescue RestClient::Exceptions::OpenTimeout => e
        verbose("Response timed out for cs3205-4.", Kanon::Logs::LogManager.VERBOSE_FATAL)
        status 503
      end
      
      response.headers['content_type'] = "application/json"
      response.headers['Content-Disposition'] = "attachment; filename=\"" + id + ".data\""
     
      response.write(result.to_json)
      verbose("Download success: JSON heartrate data summary ("+hash['uid']+")", Kanon::Logs::LogManager.VERBOSE_DEBUG)
    end

    get '/timeseriesdata/:id' do |id|
      env['warden'].authenticate!
      check?(session[:username])
      verbose("GET /heartdata/"+ id, Kanon::Logs::LogManager.VERBOSE_DEBUG)

      begin
          
        hash = {}
        hash["uid"] = id
        payload = hash.to_json

        apiResponse = Kanon::WebAPI.restTimeseries(payload)
        
        if apiResponse.code == 200
          verbose("Gotten HTTP #{apiResponse.code} from cs3205-4.", Kanon::Logs::LogManager.VERBOSE_DEBUG)
          result = JSON.parse(apiResponse.body)     
        else
          verbose("Gotten HTTP #{apiResponse.code} from cs3205-4.", Kanon::Logs::LogManager.VERBOSE_ERROR)
          status apiResponse.code
        end
      rescue RestClient::Exceptions::OpenTimeout => e
        verbose("Response timed out for cs3205-4.", Kanon::Logs::LogManager.VERBOSE_FATAL)
        status 503
      end
      
      response.headers['content_type'] = "application/json"
      response.headers['Content-Disposition'] = "attachment; filename=\"" + id + ".data\""
     
      response.write(result.to_json)
      verbose("Download success: JSON timeseries data file ("+hash['uid']+")", Kanon::Logs::LogManager.VERBOSE_DEBUG)
   

    end


    get '/update' do
      verbose("GET /update", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      env['warden'].authenticate!
      check?(session[:username])
      statsd.increment('Kanon.UpdatePassword.page_views') if checkProd?
      erb :"update", :layout => true
    end

    post '/update' do
      verbose("POST /update", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      env['warden'].authenticate!
      check?(session[:username])

      username = session[:username]
      currentpw = Sanitize.fragment(params['updatepassword']['current'])
      newpw = Sanitize.fragment(params['updatepassword']['new'])
      newpw2 = Sanitize.fragment(params['updatepassword']['new2'])
      Raven.extra_context(username: session[:username], changedUsername: username)
      if !updatePasswordCheck?(username, newpw, newpw2)
        redirect to ('/kanon/update')
      end

      payload  = {'researcher_username' => username}
    
      begin
        resource = Kanon::WebAPI.restLogin(payload.to_json)
        if (resource.code == 200)
          researcher = JSON.parse(resource.body, :symbolize_names => true)   
      
          tempUser = Kanon::Models::User.new
          tempUser.password_hash = researcher[:password]
          if tempUser.authenticate(currentpw)
            verbose("Current password provided correctly, proceeding to update password", Kanon::Logs::LogManager.VERBOSE_DEBUG)           
          else
            flash[:error] = "Existing password is incorrect. Please try again. "
            redirect to ('/kanon/update')
          end
          
        end
      rescue RestClient::Exceptions::OpenTimeout => e
        flash[:error] = "WebAPI is Down. Inform db gurus ASAP!"
        redirect to ('/kanon/update')
      end

      passwordHash = BCrypt::Password.create(newpw, :cost => 12)
      payload = {'researcher_username' => username, 'password' => passwordHash}
      verbose(username + " changing password from " + currentpw + "to " + newpw + "(hash: " + passwordHash + ") " , Kanon::Logs::LogManager.VERBOSE_DEBUG)
      
      begin
        resource = Kanon::WebAPI.restPasswordChange(payload.to_json)
        if resource.body == "Success"    
          flash[:success] = "Password changed!"
          redirect to ('/kanon/update')
        end
      rescue RestClient::Exceptions::OpenTimeout => e
        flash[:error] = "WebAPI is Down. Inform db gurus ASAP!"
        redirect to ('/kanon/update')
      end

      flash[:error] = "Oops! Something went wrong. Please try again."
      redirect '/kanon/update'     
    
    end

    not_found do
      status 404
      erb :"errors/not_found", :layout => false    
    end

    error 401 do
      status 401
      if (Kanon::Konstants.appEnvProd?)
        resource = Kanon::WebAPI.sentryIssue()
        sentryIssue = JSON.parse(resource.body, :symbolize_names => true)
        permaLink = sentryIssue[0][:permalink]
        issueID = sentryIssue[0][:id]
        resource = Kanon::WebAPI.sentryEvent(issueID)
        sentryEvent = JSON.parse(resource, :symbolize_names => true)
        eventID = sentryEvent[:id]
        @sentryLink = permaLink + "events/" + eventID
      end
      erb :"errors/internal_server_error", :layout => false
    end

    error 500...510 do
      status 500
      # start sentry code
      if (Kanon::Konstants.appEnvProd?)
        resource = Kanon::WebAPI.sentryIssue()
        sentryIssue = JSON.parse(resource.body, :symbolize_names => true)
        permaLink = sentryIssue[0][:permalink]
        issueID = sentryIssue[0][:id]
        resource = Kanon::WebAPI.sentryEvent(issueID)
        sentryEvent = JSON.parse(resource, :symbolize_names => true)
        eventID = sentryEvent[:id]
        @sentryLink = permaLink + "events/" + eventID
      end
      # end of sentry code
      erb :"errors/internal_server_error", :layout => false
    end
  end
end
