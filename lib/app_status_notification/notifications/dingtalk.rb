# frozen_string_literal: true

# Doc: https://ding-doc.dingtalk.com/doc?spm=a1zb9.8233112.0.0.340c3a88sgMlJJ#/serverapi2/qf2nxq/9e91d73c

module AppStatusNotification
  module Notification
    class Dingtalk < WebHookAdapter
      def send(message)
        send_request(url, body(message))
      end

      private

      def url
        url = webhook_url.dup
        query = url.query
        if secret_sign = generate_sign
          query = CGI.parse(query).merge(secret_sign)
          url.query = URI.encode_www_form(query)
        end

        url
      end

      def body(options)
        message = t(**options)

        {
          msgtype: :markdown,
          markdown: {
            title: message,
            text: message
          }
        }.to_json
      end

      def generate_sign
        return unless secret

        timestamp = (Time.now.to_f * 1000).to_i
        sign = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), secret, "#{timestamp}\n#{secret}")).strip

        {
          timestamp: timestamp,
          sign: sign
        }
      end

      def secret
        @secret ||= options['secret']
      end

      Notification.register self, :dingtalk, :dingding
    end
  end
end
