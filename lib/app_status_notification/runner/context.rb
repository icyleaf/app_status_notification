# frozen_string_literal: true

require 'forwardable'

class AppStatusNotification::Runner
  class Context
    extend Forwardable

    attr_reader :app, :config

    def initialize(account, app, config)
      @account = account
      @app = app
      @config = config
    end

    def client
      @client ||= AppStatusNotification::ConnectAPI.from_context(self)
    end

    def_delegators :@account, :issuer_id, :key_id, :private_key
  end
end
