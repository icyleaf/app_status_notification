# frozen_string_literal: true

# Doc: https://work.weixin.qq.com/help?doc_id=13376 or https://work.weixin.qq.com/api/doc/90000/90136/91770

module AppStatusNotification
  module Notification
    class WeCom < WebHookAdapter
      MARKDOWN_MAX_LIMITED_LENGTH = 4096

      def send(data)
        send_request(webhook_url, body(data))
      end

      private

      def body(data)
        {
          msgtype: :markdown,
          markdown: {
            content: content(data)
          }
        }.to_json
      end

      def content(data)
        message = t(data)

        if message.bytesize >= MARKDOWN_MAX_LIMITED_LENGTH
          "#{message[0..MARKDOWN_MAX_LIMITED_LENGTH-10]}\n\n..."
        else
          message
        end
      end

      Notification.register self, :wecom, :wechat_work
    end
  end
end
