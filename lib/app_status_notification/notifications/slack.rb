# frozen_string_literal: true

# Doc: https://api.slack.com/messaging/webhooks and https://app.slack.com/block-kit-builder/

module AppStatusNotification
  module Notification
    class Slack < WebHookAdapter
      def send(message)
        send_request(webhook_url, body(message))
      end

      private

      def body(message)
        message.is_a?(String) ? markdown_body(message) : card_body(message)
      end

      def markdown_body(message)
        {
          type: :mrkdwn,
          text: message
        }.to_json
      end

      def card_body(message)
        {
          blocks: [
            {
              type: :section,
              text: {
                type: :mrkdwn,
                text: t(**message),
              }
            },
            {
              type: :section,
              fields: [
                {
                  type: :mrkdwn,
                  text: "*版本:*\n#{message[:version]}"
                },
                {
                  type: :mrkdwn,
                  text: "*状态:*\n#{message[:status]}"
                }
              ]
            }
          ]
        }.to_json
      end

      def token
        @token ||= options['token']
      end

      def channel
        @channel ||= options['channel']
      end

      Notification.register self, :slack
    end
  end
end
