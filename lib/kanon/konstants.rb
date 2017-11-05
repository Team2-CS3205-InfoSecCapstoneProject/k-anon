
# anyway we can use this to control global constants?
# maybe this can be our config file to turn on/off various protections too


module Kanon
	class Konstants
		
		# set the verbosiveness here. 
		# 0 - DEBUG, 1 - INFO, 2 - ERROR, 3 - FATAL
		# 0 - Shows everything >= 0
		# 4 - Shows nothing (nothing >= 4)
		LOGGER_VERBOSE_LEVEL = 0

		def self.getVerboseLevel()
			return LOGGER_VERBOSE_LEVEL
		end

		WEB_ROOT='/' # should be '/' (prod) or '/kanon/' (dev)
		XSS_ENABLED=false
		CSRF_ENABLED=false

		APP_ENV = ENV['ENVIRONMENT']

		GOOGLE_CAPTCHA_LINK = "https://www.google.com/recaptcha/api/siteverify"
		GOOGLE_SECRET = ENV['GOOGLESECRET']

		SENTRY_REPORT_LINK = ENV['SENTRYREPORTLINK']
		SENTRY_API_KEY = ENV['SENTRYAPIKEY']
		SENTRY_API_ISSUE = "https://sentry.io/api/0/projects/cs3205-team2-kanon/kanon/issues"
		SENTRY_API_EVENT = "https://sentry.io/api/0/issues"

		API_BASE_URL = "https://cs3205-4-i.comp.nus.edu.sg/api/team2"
		API_USER = ENV['S4APIUSER']
		API_SECRET = ENV['S4APISECRET']
		API_KEY = ENV['S2APIKEY']
		API_CERT = ENV['S2APICERT']
		API_CA = ENV['S4CA']

		# set the value of k for k-anonymity here. 
		# 0 - K-ANON OFF
		# 1 - GENERALIZATION ON
		# 2++ - GENERALIZATION AND SUPPRESSION ON
		K = 3

		def self.appEnvProd?()
			if "#{APP_ENV}" == "PRODUCTION"
				return true
			end
		end

		def self.apiUser()
			return "#{API_USER}"
		end

		def self.apiSecret()
			return "#{API_SECRET}"
		end

		def self.apiKey()
			return "#{API_KEY}"
		end

		def self.apiCert()
			return "#{API_CERT}"
		end

		def self.apiCA()
			return "#{API_CA}"
		end

		def self.googleCaptchaURI()
			return "#{GOOGLE_CAPTCHA_LINK}"
		end

		def self.googleSecret()
			return "#{GOOGLE_SECRET}"
		end

		def self.sentryReportLink()
			return "#{SENTRY_REPORT_LINK}/"
		end

		def self.sentryAPIKey()
			return "#{SENTRY_API_KEY}/"
		end

		def self.sentryIssueAPI()
			return "#{SENTRY_API_ISSUE}/"
		end

		def self.sentryEventAPI(issueID)
			return "#{SENTRY_API_EVENT}/" + issueID + "/events/latest/"
		end

		def self.restLoginURI()
			return "#{API_BASE_URL}/researcher/login"
		end

		def self.restGetResearcherURI(username)
			return "#{API_BASE_URL}/researcher/" + username
		end

		def self.restRegisterURI()
			return "#{API_BASE_URL}/researcher/register"
		end

		def self.restConfigureOTPURI()
			return "#{API_BASE_URL}/researcher/registerOTP"
		end

		def self.restCheckOTPURI(username)
			return "#{API_BASE_URL}/researcher/OTPenabled/" + username
		end

		def self.restSearchURI()
			return "#{API_BASE_URL}/search"
		end
		
		def self.restFetchURI()
			return "#{API_BASE_URL}/fetch"
		end

		def self.restHeartURI()
			return "#{API_BASE_URL}/heart"
		end

		def self.restTimeseriesURI()
			return "#{API_BASE_URL}/timeseries"
		end

		def self.restListCategoriesURI()
			return "#{API_BASE_URL}/category/list"
		end

		def self.restListNationalityURI()
			return "#{API_BASE_URL}/nationality"
		end

		def self.restListEthnicityURI()
			return "#{API_BASE_URL}/ethnicity"
		end

		def self.restCategoryInfoURI()
			return "#{API_BASE_URL}/category/info"
		end

		def self.restCategoryListURI(researcher_id)
			return "#{API_BASE_URL}/category/list/" + researcher_id
		end

		def self.restCategoryRequestURI()
			return "#{API_BASE_URL}/category/request"
		end

		def self.restListFiltersURI()
			return "#{API_BASE_URL}/filters"
    	end

   		def self.restCategoryListAllURI()
			return "#{API_BASE_URL}/category/list/all"
		end

		def self.restCategoryApproveURI()
			return "#{API_BASE_URL}/category/approve"
		end

		def self.restCategoryDeclineURI()
			return "#{API_BASE_URL}/category/decline"
		end		
		
		def self.restPasswordChangeURI()
			return "#{API_BASE_URL}/researcher/passwordChange"
		end
		
		def self.k()
			return K
		end
	end
end
