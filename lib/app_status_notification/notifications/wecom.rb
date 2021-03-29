# frozen_string_literal: true

# Doc: https://work.weixin.qq.com/help?doc_id=13376 or https://work.weixin.qq.com/api/doc/90000/90136/91770

module AppStatusNotification
  module Notification
    class WeCom < Adapter
      attr_reader :exception

      MARKDOWN_MAX_LIMITED_LENGTH = 4096

      @exception = nil

      def initialize(options)
        @webhook_url = URI(options['webhook_url'])
        super
      end

      def send(message)
        @exception = nil

        message = t(message)
        content = if message.bytesize >= MARKDOWN_MAX_LIMITED_LENGTH
                    "#{message[0..MARKDOWN_MAX_LIMITED_LENGTH-10]}\n\n..."
                  else
                    message
                  end

        data = {
          msgtype: :markdown,
          markdown: {
            content: content
          }
        }

        response = Net::HTTP.post(@webhook_url, data.to_json, 'Content-Type' => 'application/json')
        logger.debug "#{self.class} response [#{response.code}] #{response.body}"
      rescue => e
        @exception = e
        nil
      end

      Notification.register self, :wecom, :wechat_work
    end
  end
end
