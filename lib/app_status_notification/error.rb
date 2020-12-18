# frozen_string_literal: true

module AppStatusNotification
  class Error < StandardError; end

  class ConfigError < Error; end
  class MissingAppsConfigError < ConfigError; end
  class UnknownNotificationError < ConfigError; end

  class ConnectAPIError < Error
    class << self
      def parse(response)
        errors = response.body['errors']
        case response.status
        when 401
          InvalidUserCredentialsError.from_errors(errors)
        when 409
          InvalidEntityError.from_errors(errors)
        else
          ConnectAPIError.from_errors(errors)
        end
      end

      def from_errors(errors)
        message = ["Check errors(#{errors.size}) from response:"]
        errors.each_with_index do |error, i|
          message << "#{i + 1} - [#{error['status']}] #{error['title']}: #{error['detail']} in #{error['source']}"
        end

        new(message)
      end
    end
  end

  class RateLimitExceededError < ConnectAPIError; end
  class InvalidEntityError < ConnectAPIError; end
  class InvalidUserCredentialsError < ConnectAPIError; end
end
