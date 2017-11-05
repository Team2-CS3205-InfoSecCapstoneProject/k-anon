module Kanon
  class WebAPI

    def restGet(url)
      begin
        resource = RestClient::Request.execute(
          method: :get, 
          url: url, 
          :headers => {content_type: :json},
          user: Kanon::Konstants.apiUser,
          password: Kanon::Konstants.apiSecret,
          :ssl_client_cert => OpenSSL::X509::Certificate.new(File.read(Kanon::Konstants.apiCert)),
          :ssl_client_key   =>  OpenSSL::PKey::RSA.new(File.read(Kanon::Konstants.apiKey)),
          :ssl_ca_file      =>  Kanon::Konstants.apiCA,
          :verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER,
          timeout: 10)
        return resource
      rescue RestClient::Exceptions::OpenTimeout => e
        throw(:warden, message: "WebAPI Timeout!")
      end
    end

    def restPost(url, payload)
      begin
        resource = RestClient::Request.execute(
          method: :post, 
          url: url, 
          payload: payload, :headers => {content_type: :json,:accept => :json},
          user: Kanon::Konstants.apiUser,
          password: Kanon::Konstants.apiSecret,
          :ssl_client_cert => OpenSSL::X509::Certificate.new(File.read(Kanon::Konstants.apiCert)),
          :ssl_client_key   =>  OpenSSL::PKey::RSA.new(File.read(Kanon::Konstants.apiKey)),
          :ssl_ca_file      =>  Kanon::Konstants.apiCA,
          :verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER,
          timeout: 10)
        return resource
      rescue RestClient::Exceptions::OpenTimeout => e
        throw(:warden, message: "WebAPI Timeout!")
      end
    end

    def restPut(url, payload)
      begin
        resource = RestClient::Request.execute(
          method: :put, 
          url: url, 
          payload: payload, :headers => {content_type: :json,:accept => :json},
          user: Kanon::Konstants.apiUser,
          password: Kanon::Konstants.apiSecret,
          :ssl_client_cert => OpenSSL::X509::Certificate.new(File.read(Kanon::Konstants.apiCert)),
          :ssl_client_key   =>  OpenSSL::PKey::RSA.new(File.read(Kanon::Konstants.apiKey)),
          :ssl_ca_file      =>  Kanon::Konstants.apiCA,
          :verify_ssl       =>  OpenSSL::SSL::VERIFY_PEER,
          timeout: 10)
        return resource
      rescue RestClient::Exceptions::OpenTimeout => e
        throw(:warden, message: "WebAPI Timeout!")
      end
    end

    def self.restLogin(payload)
      WebAPI.new.restPost(Kanon::Konstants.restLoginURI, payload)
    end

    def self.restRegister(payload)
      WebAPI.new.restPost(Kanon::Konstants.restRegisterURI, payload)
    end

    def self.restConfigureOTP(payload)
      WebAPI.new.restPut(Kanon::Konstants.restConfigureOTPURI, payload)      
    end

    def self.restCheckOTP(username)
      WebAPI.new.restGet(Kanon::Konstants.restCheckOTPURI(username))
    end

    def self.restGetResearcher(username)
      WebAPI.new.restGet(Kanon::Konstants.restGetResearcherURI(username))
    end

    def self.restSearch(payload)
      WebAPI.new.restPost(Kanon::Konstants.restSearchURI, payload)
    end

    def self.restHeart(payload)
      WebAPI.new.restPost(Kanon::Konstants.restHeartURI, payload)
    end

    def self.restTimeseries(payload)
      WebAPI.new.restPost(Kanon::Konstants.restTimeseriesURI, payload)
    end

    def self.restListCategories()
      WebAPI.new.restGet(Kanon::Konstants.restListCategoriesURI)
    end

    def self.restCategoryInfo()
      WebAPI.new.restGet(Kanon::Konstants.restCategoryInfoURI)
    end

    def self.restCategoryList(researcher_id)
      WebAPI.new.restGet(Kanon::Konstants.restCategoryListURI(researcher_id))
    end

    def self.restListFilters()
      WebAPI.new.restGet(Kanon::Konstants.restListFiltersURI)
    end

    def self.restListNationality()
      WebAPI.new.restGet(Kanon::Konstants.restListNationalityURI)
    end

    def self.restListEthnicity()
      WebAPI.new.restGet(Kanon::Konstants.restListEthnicityURI)
    end

    def self.restCategoryRequest(payload)
      WebAPI.new.restPost(Kanon::Konstants.restCategoryRequestURI, payload)
    end

    def self.restCategoryListAll()
      WebAPI.new.restGet(Kanon::Konstants.restCategoryListAllURI)
    end

    def self.restCategoryApprove(payload)
      WebAPI.new.restPost(Kanon::Konstants.restCategoryApproveURI, payload)
    end

    def self.restCategoryDecline(payload)
      WebAPI.new.restPost(Kanon::Konstants.restCategoryDeclineURI, payload)
    end

    def self.restPasswordChange(payload)
      WebAPI.new.restPut(Kanon::Konstants.restPasswordChangeURI, payload)
    end

    def self.sentryIssue()
      sleep 5
    	resource = RestClient.get Kanon::Konstants.sentryIssueAPI, {:Authorization => Kanon::Konstants.sentryAPIKey}
    	return resource
    end

    def self.sentryEvent(issueID)
    	resource = RestClient.get Kanon::Konstants.sentryEventAPI(issueID), {:Authorization => Kanon::Konstants.sentryAPIKey}
  	return resource
    end

    def self.googleCaptcha(response)
      resource = RestClient.post Kanon::Konstants.googleCaptchaURI, {secret: Kanon::Konstants.googleSecret, response: response}
    end
  end
end
