# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'

require 'app_status_notification/connect_api/auth'
require 'app_status_notification/connect_api/response'
require 'app_status_notification/connect_api/model'

module AppStatusNotification
  class ConnectAPI
    Dir[File.expand_path('connect_api/clients/*.rb', __dir__)].each { |f| require f }

    ENDPOINT = 'https://api.appstoreconnect.apple.com/v1'

    include Client::App
    include Client::AppStoreVersion
    include Client::Build

    def self.from_context(context, **kargs)
      new(**kargs.merge(
        issuer_id: context.issuer_id,
        key_id: context.key_id,
        private_key: context.private_key,
      ))
    end

    attr_reader :connection

    def initialize(**kargs)
      configure_connection(**kargs)
    end

    %w[get post patch delete].each do |method|
      define_method method do |path, options = {}|
        params = options.dup

        if %w[post patch].include?(method)
          body = params[:body].to_json
          headers = params[:headers] || {}
          headers[:content_type] ||= 'application/json'
          validates connection.send(method, path, body, headers)
        else
          validates connection.send(method, path, params)
        end
      end
    end

    private

    def validates(response)
      case response.status
      when 200, 201, 204
        # 200: get requests
        # 201: post requests
        # 204: patch, delete requests
        handle_response response
      when 429
        # 429 Rate Limit Exceeded
        raise RateLimitExceededError.parse(response)
      else
        raise ConnectAPIError.parse(response)
      end
    end

    def handle_response(response)
      response = Response.new(response, connection)

      if (remaining = response.rate[:remaining]) && remaining.to_i.zero?
        raise RateLimitExceededError, "Request limit reached #{response.rate[:limit]} in the previous 60 minutes with url: #{response.request_url}"
      end

      response
    end

    def configure_connection(**kargs)
      @auth = Auth.new(**kargs)
      endpoint = kargs[:endpoint] || ENDPOINT

      connection_opts= {}
      connection_opts[:proxy] = ENV['ASN_PROXY'] if ENV['ASN_PROXY']
      @connection = Faraday.new(endpoint, connection_opts) do |builder|
        builder.request :url_encoded
        builder.request :authorization, 'Bearer', @auth.token
        builder.headers[:content_type] = 'application/json'

        builder.response :json, content_type: /\bjson$/
        builder.response :logger if kargs[:debug] || ENV['ASN_DEBUG']
      end
    end
  end
end
