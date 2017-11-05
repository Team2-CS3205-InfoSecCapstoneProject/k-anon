module Kanon
	module AppHelper

    def verbose(message, level = LogManager::VERBOSE_DEBUG)
      Kanon::Logs::LogManager.verbose(message, level)
    end

    def strip_ids!(json, block = Proc.new)
      json.each_with_object([]) { |inVal, outVal|
        inVal.each { |key, value|
          if value.is_a? Array
            inVal[key] = strip_ids! value, block
          else
            inVal.delete(key) if block.call key
          end
        }
        outVal << inVal
      }
    end

    def prepareFormat(json)
      result = Array.new
      json.each { |record|
        hash = Hash.new
        hash["id"] = nil
        hash["isset"] = "1"
        hash["key"] = record["result"]
        hash["parent_id"] = nil
        hash["type"] = "3"
        hash["value"] = record["result"]
        result.push(hash)
      }
      return result
    end

    def getSearchResultFilters()
      begin
        verbose("Getting search filters", Kanon::Logs::LogManager.VERBOSE_DEBUG)
        apiResponse = Kanon::WebAPI.restListFilters()

        if apiResponse.code == 200
          verbose("Gotten HTTP #{apiResponse.code} from cs3205-4.", Kanon::Logs::LogManager.VERBOSE_DEBUG)
          json = JSON.parse(apiResponse.body)
          return json
        else
          verbose("Gotten HTTP #{apiResponse.code} from cs3205-4.", Kanon::Logs::LogManager.VERBOSE_ERROR)
        end
      rescue RestClient::Exceptions::OpenTimeout => e
        verbose("Response timed out for cs3205-4.", Kanon::Logs::LogManager.VERBOSE_FATAL)
      end
      return JSON.parse("{}")
    end

    def getNationalityFilters()
      begin
        verbose("Getting nationality filters", Kanon::Logs::LogManager.VERBOSE_DEBUG)
        apiResponse = Kanon::WebAPI.restListNationality()

        if apiResponse.code == 200
          verbose("Gotten HTTP #{apiResponse.code} from cs3205-4.", Kanon::Logs::LogManager.VERBOSE_DEBUG)
          json = JSON.parse(apiResponse.body)
          return json
        else
          verbose("Gotten HTTP #{apiResponse.code} from cs3205-4.", Kanon::Logs::LogManager.VERBOSE_ERROR)
        end
      rescue RestClient::Exceptions::OpenTimeout => e
        verbose("Response timed out for cs3205-4.", Kanon::Logs::LogManager.VERBOSE_FATAL)
      end
      return JSON.parse("{}")
    end

    def getEthnicityFilters()
      begin
        verbose("Getting ethnicity filters", Kanon::Logs::LogManager.VERBOSE_DEBUG)
        apiResponse = Kanon::WebAPI.restListEthnicity()

        if apiResponse.code == 200
          verbose("Gotten HTTP #{apiResponse.code} from cs3205-4.", Kanon::Logs::LogManager.VERBOSE_DEBUG)
          json = JSON.parse(apiResponse.body)
          return json
        else
          verbose("Gotten HTTP #{apiResponse.code} from cs3205-4.", Kanon::Logs::LogManager.VERBOSE_ERROR)
        end
      rescue RestClient::Exceptions::OpenTimeout => e
        verbose("Response timed out for cs3205-4.", Kanon::Logs::LogManager.VERBOSE_FATAL)
      end
      return JSON.parse("{}")
    end

    def getPermittedSearchConditions(researchCategories)
      begin
        verbose("Getting permitted conditions for #{researchCategories}", Kanon::Logs::LogManager.VERBOSE_DEBUG)
        apiResponse = Kanon::WebAPI.restListCategories()

        if apiResponse.code == 200
          verbose("Gotten HTTP #{apiResponse.code} from cs3205-4.", Kanon::Logs::LogManager.VERBOSE_DEBUG)
          json = JSON.parse(apiResponse.body)
          
          conditions = Hash.new

          json.each { |element|
              category_id = element["category_id"]
              if (researchCategories.include? category_id)
                  element["conditions"].each { |condition|
                      id = condition["condition_id"]
                      name = condition["condition_name"]
                      conditions[name] = id
                  }
              end
          } unless researchCategories.nil?

          result = JSON.generate(conditions)
          verbose("Permitted conditions are #{result.to_s}.", Kanon::Logs::LogManager.VERBOSE_DEBUG)
          return JSON.parse(result)
        else
          verbose("Gotten HTTP #{apiResponse.code} from cs3205-4.", Kanon::Logs::LogManager.VERBOSE_ERROR)
        end
      rescue RestClient::Exceptions::OpenTimeout => e
        verbose("Response timed out for cs3205-4.", Kanon::Logs::LogManager.VERBOSE_FATAL)
      end
      return JSON.parse("{}")
    end

    def filterConditions(researchCategories, conditions)
      verbose("Filtering conditions for #{researchCategories}", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      
      filteredConditions = Array.new
      permittedConditions = getPermittedSearchConditions(researchCategories)
      
      conditions.each { |condition| 
        if (permittedConditions.values.include? condition)
          filteredConditions.push condition
        end
      } unless conditions.nil?

      permittedConditions.values.each { |value|
        filteredConditions.push value
      } unless filteredConditions.count > 0

      filteredConditions.push -1 unless filteredConditions.count > 0

      verbose("Filtered conditions are #{filteredConditions.to_json}", Kanon::Logs::LogManager.VERBOSE_DEBUG)
      return filteredConditions
    end

    def emptyString(string)
      if string.empty?
        flash[:error] = "Empty field detected"
        return false
      else
        return true
      end
    end

    def passwordMinLength(string)
      if string.length < 8
        flash[:error] = "Password too short"
        return false
      else
        return true
      end
    end

    def passwordConfirm(password, confirmPassword)
      if (password != confirmPassword)
        flash[:error] = "Password does not match."
        return false
      else
        return true
      end
    end

    def registerCheck?(firstname, lastname, username, password, confirmPassword)
      if emptyString(firstname) && emptyString(lastname) && emptyString(username) && 
        emptyString(password) && emptyString(confirmPassword) &&
        passwordMinLength(password) && passwordMinLength(confirmPassword) && 
        passwordConfirm(password, confirmPassword)
        return true
      else
        return false
      end
    end

    def updatePasswordCheck?(username, password, confirmPassword)
    	if emptyString(username) && emptyString(password) && emptyString(confirmPassword) &&
    		passwordMinLength(password) && passwordMinLength(confirmPassword) &&
    		passwordConfirm(password, confirmPassword)
    		return true
    	else
    		return false
    	end
    end

    def checkProd?
      if (Kanon::Konstants.appEnvProd?)
        return true
      else
        return false
      end
    end

    def countOnlineUser()
      noOfUsers = Kanon::Models::User.count()
      return noOfUsers
    end

    def validOTP?
      if !session[:isOTP]
        redirect '/kanon/auth/logout'
      end
    end

    def protect_from_request_forgery!
      session[:csrf] ||= SecureRandom.hex(64)
      halt(403, "CSRF attack prevented") if csrf_attack?
    end

    def csrf_token_from_request
      csrf_token = env["HTTP_X_CSRF_TOKEN"] || params["_csrf"]
      halt(403, "CSRF token not present in request") if csrf_token.to_s.empty?
      csrf_token
    end

    def csrf_attack?
      !request.safe? && csrf_token_from_request != session[:csrf]
    end

	end
end