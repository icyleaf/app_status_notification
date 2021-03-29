# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module AppStatusNotification
  module Notification
    class Adapter
      include AppStatusNotification::I18nHelper

      def initialize(options = {}) # rubocop:disable Style/OptionHash
        @options = options
        @logger = @options[:logger]
      end

      # def send(message)
      #   fail Error, 'Adapter does not supports #send'
      # end

      # def on_error(exception)
      #   fail Error, "Adapter does not supports #send"
      # end

      private

      def logger
        @logger
      end
    end
  end
end
