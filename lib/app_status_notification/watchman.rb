# frozen_string_literal: true

require 'app_status_notification/runner'
require 'fileutils'

module AppStatusNotification
  class Watchman
    include AppStatusNotification::I18nHelper

    def self.run(config_path = nil, store_path = nil, test_mode: false)
      Anyway::Settings.default_config_path = config_path if config_path && Dir.exist?(config_path)

      config = Config.new(test_mode: test_mode)
      if store_path
        FileUtils.mkdir_p(store_path)
        config.store_path = store_path
      end

      yield config if block_given?

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
      @logger.info t('logger.current_env', name: config.env, version: AppStatusNotification::VERSION)
      @logger.debug config
    end
  end
end
