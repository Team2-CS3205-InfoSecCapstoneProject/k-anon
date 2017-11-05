module Kanon
    module Logs
        class LogManager
            # begin VERBOSIVE controls
            # controls the verbosiveness of the application in web_app.rb
            VERBOSE_DEBUG = 0
            VERBOSE_INFO = 1
            VERBOSE_ERROR = 2
            VERBOSE_FATAL = 3

            def self.VERBOSE_DEBUG
                return VERBOSE_DEBUG
            end

            def self.VERBOSE_INFO
                return VERBOSE_INFO
            end

            def self.VERBOSE_ERROR
                return VERBOSE_ERROR
            end

            def self.VERBOSE_FATAL
                return VERBOSE_FATAL
            end

            def self.verbose(message, level = VERBOSE_DEBUG)
                if level >= Konstants.getVerboseLevel()
                    if level == VERBOSE_DEBUG
                        puts "(DEBUG) #{message}\n"
                    elsif level == VERBOSE_INFO
                        puts "(INFO) #{message}\n"
                    elsif level == VERBOSE_ERROR
                        puts "(ERROR) #{message}\n"
                    elsif level == VERBOSE_FATAL
                        puts "(FATAL) #{message}\n"
                    else
                        # shouldn't get here.
                        #puts "(NOLEVEL) #{message}\n"
                    end
                end
            end
        end
    end
end