# frozen_string_literal: true

module AppStatusNotification
  module Notification
    class << self
      def register(adapter, type, *shortcuts)
        adapters[type.to_sym] = adapter

        shortcuts.each do |name|
          aliases[name.to_sym] = type.to_sym
        end
      end

      def [](type)
        adapters[normalize(type)] || raise(UnknownNotificationError, "Unknown notication: #{type}")
      end

      def send(message, options)
        opts = options.dup
        adapter = opts.delete('type')
        notification = Notification[adapter].new(opts)
        notification.send(message)
      end

      private

      # :nodoc:
      def normalize(type)
        aliases.fetch(type, type.to_sym)
      end

      # :nodoc:
      def adapters
        @adapters ||= {}
      end

      # :nodoc:
      def aliases
        @aliases ||= {}
      end
    end

    class Message
      attr_accessor :app, :version, :build

      def initialize(app, version, build)
        @app = app
        @version = version
        @build = build
      end
    end
  end
end

require 'app_status_notification/notifications/adapter'
require 'app_status_notification/notifications/wecom'
require 'app_status_notification/notifications/slack'
require 'app_status_notification/notifications/dingtalk'
