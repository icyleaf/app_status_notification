# frozen_string_literal: true

require 'app_status_notification/runner'

module AppStatusNotification
  class Watchman
    include AppStatusNotification::I18nHelper

    def self.run(config_file)
      if config_file.nil? && block_given?
        config = Config.new
        yield config
      else
        config = Config.new(config_file)
      end

      Watchman.new(config).run
    end

    attr_reader :config, :client, :logger

    def initialize(config)
      @config = config
      configure_logger
    end

    def run
      @logger.info t('logger.setup_accounts', numbers: config.accounts.size)
      config.accounts.each do |account|
        @logger.info t('logger.setup_apps', issuer_id: account.issuer_id, apps: account.apps.size)
        account.apps.each do |app|
          context = AppStatusNotification::Runner::Context.new(account, app, config)
          Runner.new(context).start
        end
      end
    end

    def configure_logger
      @logger ||= config.logger
      @logger.info t('logger.current_env', name: config.env)
      @logger.debug config
    end
  end
end
