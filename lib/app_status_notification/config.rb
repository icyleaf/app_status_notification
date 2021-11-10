# frozen_string_literal: true

require 'app_status_notification/version'
require 'anyway_config'
require 'sentry-ruby'
require 'logger'
require 'i18n'

module AppStatusNotification
  class Config < Anyway::Config
    config_name :notification

    attr_config accounts: [],
                notifications: {},
                refresh_interval: 60,
                locale: 'zh',
                store_path: 'stores',
                dry: false,
                test_mode: false,
                enable_crash_report: true,
                crash_report: 'https://aa7c78acbb324fcf93169fce2b7e5758@o333914.ingest.sentry.io/5575774'

    def load_locale(path, file = '*.yml')
      paths = File.join(path, file) unless path.end_with?(file)
      I18n.load_path += Dir[paths]
    end

    def debug?
      (ENV['ASN_ENV'] || ENV['RACK_ENV'] || ENV['RAILS_ENV']) != 'production'
    end

    def dry?
      !!dry
    end

    def env
      debug? ? 'development' : 'production'
    end

    def logger
      return @logger if @logger

      @logger = Logger.new(STDOUT)
      @logger.level = debug? ? Logger::DEBUG : Logger::INFO
      @logger
    end

    def accounts
      @account ||= Account.parse(super)
    end

    def config_path
      Anyway::Settings.default_config_path
    end

    on_load :configure_locale
    on_load :ensure_accounts
    on_load :ensure_notifications
    on_load :configure_crash_report

    private

    def builtin_config_path
      @builtin_config_path ||= File.join(File.expand_path('../../', __dir__), 'config')
    end

    def configure_locale
      # built-in
      I18n.load_path << Dir[File.join(builtin_config_path, 'locales', '*.yml')]

      # default locale
      I18n.locale = locale.to_sym
    end

    def configure_crash_report
      return unless enable_crash_report

      Sentry.init do |config|
        config.send_default_pii = true
        config.dsn = crash_report
        config.environment = env
        config.release = AppStatusNotification::VERSION
        config.excluded_exceptions += [
          'Faraday::SSLError',
          'Spaceship::UnauthorizedAccessError',
          'Interrupt',
          'SystemExit',
          'SignalException',
          'Faraday::ConnectionFailed'
        ]

        config.before_send = lambda { |event, hint|
          event.extra = {
            config: self.to_filtered_h
          }

          event
        }
      end
    end

    def ensure_accounts
      %w[key_id issuer_id apps].each do |key|
        accounts.each do |account|
          unless account.send(key.to_sym)
            raise ConfigError, "Missing account properties: #{key}"
          end

          unless account.key_path && account.key_exists?
            raise ConfigError, "Can not find key file, place one into config directory, Eg: config/AuthKey_xxx.p8"
          end
        end
      end
    end

    def ensure_notifications
      if notifications.nil? || notifications.empty?
        raise ConfigError, "Missing notifications"
      elsif notifications.is_a?(Hash)
        notifications.each do |key, url|
          raise ConfigError, "Missing url properties: #{key}" unless url
        end
      end
    end

    def to_filtered_h
      @to_filtered_h ||= to_h.each_with_object({}) do |(k, v), obj|
        case k
        when :accounts
          obj[k] = filter_accounts
        when :notifications
          obj[k] = filter_notifications(v)
        when :crash_report
          obj[k] = filtered_token(v)
        else
          obj[k] = v
        end
      end
    end

    def filter_accounts
      accounts.each_with_object([]) do |account,  obj|
        item = {
          issuer_id: filtered_token(account.issuer_id),
          key_id: filtered_token(account.key_id),
          key_path: filtered_token(account.key_path),
          apps: []
        }

        account.apps.each do |app|
          item[:apps] << {
            id: filtered_token(app.id),
            notifications: app.notifications
          }
        end

        obj << item
      end
    end

    def filter_notifications(notifications)
      notifications.each_with_object({}) do |(k, v), obj|
        new_v = v.dup
        new_v['webhook_url'] = filtered_token(new_v['webhook_url'])
        obj[k] = new_v
      end
    end

    def filtered_token(chars)
      chars = chars.to_s
      return '*' * chars.size if chars.size < 4

      average = chars.size / 4
      prefix = chars[0..average - 1]
      hidden = '*' * (average * 2)
      suffix = chars[(prefix.size + average * 2)..-1]
      "#{prefix}#{hidden}#{suffix}"
    end

    class Account
      def self.parse(accounts)
        [].tap do |obj|
          accounts.each do |account|
            obj << Account.new(account)
          end
        end
      end

      attr_reader :issuer_id, :key_id, :key_path
      attr_reader :apps

      def initialize(raw)
        @issuer_id = raw['issuer_id']
        @key_id = raw['key_id']
        @key_path = raw['key_path']
        @apps = App.parse(raw['apps'])
      end

      def key_exists?
        File.file?(key_path) || File.readable?(key_path)
      end

      def private_key
        File.read(key_path)
      end

      class App
        def self.parse(apps)
          raise MissingAppsConfigError, 'Unable handle all apps of account,
            add app id(s) under accounts with name `apps`.' unless apps

          [].tap do |obj|
            apps.each do |app|
              obj << App.new(app)
            end
          end
        end

        attr_reader :id

        def initialize(raw)
          case raw
          when String, Integer
            @id = raw.to_s
          when Hash
            @id = raw['id'].to_s
            @notifications = raw['notifications']
          end
        end

        def notifications
          @notifications ||= []
        end
      end
    end
  end
end
