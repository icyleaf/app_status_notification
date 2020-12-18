# frozen_string_literal: true

# Doc: https://ding-doc.dingtalk.com/doc?spm=a1zb9.8233112.0.0.340c3a88sgMlJJ#/serverapi2/qf2nxq/9e91d73c

module AppStatusNotification
  module Notification
    class Dingtalk < Adapter
      def initialize(options)
        @webhook_url = URI(options['webhook_url'])
        @secret = options['secret']

        super
      end

      def send(message)
        message = t(**message)

        data = {
          msgtype: :markdown,
          markdown: {
            title: message,
            text: message
          }
        }

        response = Net::HTTP.post(build_url, data.to_json, 'Content-Type' => 'application/json')
        ap response.code
        ap response.body
      # rescue => e
      #   @exception = e
      #   nil
      end

      def build_url
        url = @webhook_url.dup
        query = url.query
        if secret_sign = generate_sign
          query = CGI.parse(query).merge(secret_sign)
        end
        url.query = URI.encode_www_form(query)
        url
      end

      def generate_sign
        return unless @secret

        timestamp = (Time.now.to_f * 1000).to_i
        sign = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), @secret, "#{timestamp}\n#{@secret}")).strip

        {
          timestamp: timestamp,
          sign: sign
        }
      end

      Notification.register self, :dingtalk, :dingding
    end
  end
end
