# frozen_string_literal: true

# Doc: https://open.feishu.cn/document/ukTMukTMukTM/ucTM5YjL3ETO24yNxkjN#8b0f2a1b

module AppStatusNotification
  module Notification
    class Feishu < WebHookAdapter
      def send(message)
        send_request(webhook_url, body(message))
      end

      private

      def body(options)
        message = t(**options)

        generate_sign.merge(
          msg_type: :interactive,
          card: {
            config: {
              wide_screen_mode: true,
              enable_forward: true
            },
            elements: [
              {
                tag: :div,
                text: {
                  tag: :lark_md,
                  content: message
                }
              }
            ]
          }
        ).to_json
      end

      def generate_sign
        return unless secret

        timestamp = Time.now.to_i.to_s
        hmac = OpenSSL::HMAC.new("#{timestamp}\n#{secret}", OpenSSL::Digest.new('sha256')).digest
        sign = Base64.encode64(hmac).strip

        {
          timestamp: timestamp,
          sign: sign
        }
      end

      def secret
        @secret ||= options['secret']
      end

      Notification.register self, :feishu, :lark
    end
  end
end
