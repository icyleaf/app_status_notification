# frozen_string_literal: true

require 'forwardable'

class AppStatusNotification::Runner
  class Context
    extend Forwardable

    attr_reader :app, :config
    def_delegators :@account, :issuer_id, :key_id, :private_key

    def initialize(account, app, config)
      @account = account
      @app = app
      @config = config
    end

    def client
      @client ||= TinyAppstoreConnect::Client.new(
        issuer_id: issuer_id,
        key_id: key_id,
        private_key: private_key
      )
    end
  end
end
