# frozen_string_literal: true

require 'forwardable'

module AppStatusNotification
  class ConnectAPI
    class Response
      include Enumerable
      extend Forwardable

      attr_reader :response, :connection

      def initialize(response, connection)
        @response = response
        @connection = connection
      end

      def_delegators :@response, :status, :headers

      def request_url
        @response.env.url
      end

      def rate
        return {} unless value = response.headers[:x_rate_limit]

        value.split(';').inject({}) do |r, q|
          k, v = q.split(':')
          case k
          when 'user-hour-lim'
            r.merge!(limit: v)
          when 'user-hour-rem'
            r.merge!(remaining: v)
          end
        end
      end

      def next_link
        return if response.nil?

        links = response[:links] || {}
        links[:next]
      end

      # def all_pages
      #   next_pages(count: 0)
      # end

      # def next_pages(count: 1)
      #   count = count.to_i
      #   count = 0 if count <= 0

      #   responses = [self]
      #   counter = 0

      #   resp = self
      #   loop do
      #     resp = resp.next_page
      #     break if resp.nil?

      #     responses << resp
      #     counter += 1

      #     break if counter >= count
      #   end

      #   responses
      # end

      # def next_url
      #   return if response.nil?

      #   links = response[:links] || {}
      #   links[:next]
      # end

      # def next_page
      #   return unless url = next_url

      #   Response.new(connection.get(url), connection)
      # end

      def to_model
        to_models.first
      end

      def to_models
        return [] if response.nil?

        model_or_models = ConnectAPI::Parser.parse(response, rate)
        [model_or_models].flatten
      end

      def each(&block)
        to_models.each do |model|
          yield(model)
        end
      end
    end
  end
end

