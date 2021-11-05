# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module AppStatusNotification
  module Notification
    class Adapter
      include AppStatusNotification::I18nHelper

      attr_reader :options

      def initialize(options = {}) # rubocop:disable Style/OptionHash
        @options = options
      end

      # def send(message)
      #   fail Error, 'Adapter does not supports #send'
      # end

      # def on_error(exception)
      #   fail Error, "Adapter does not supports #send"
      # end

      protected

      def logger
        @logger ||= @options['logger']
      end
    end

    class WebHookAdapter < Adapter
      protected

      def send_request(url, body, method: :post, content_type: 'application/json')
        logger.debug "#{self.class} request [#{method}] #{url} with json #{body}"
        response = Net::HTTP.send(method, url, body, 'Content-Type' => content_type)
        logger.debug "#{self.class} response [#{response.code}] #{response.body}"
        response
      rescue => exception
        @exception = exception
        logger.error exception
        logger.error @exception.backtrace.join("\n")
        nil
      end

      def webhook_url
        @webhook_url ||= URI(@options['webhook_url'])
      end
    end
  end
end
