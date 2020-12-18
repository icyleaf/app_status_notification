# frozen_string_literal: true

# Doc: https://api.slack.com/messaging/webhooks and https://app.slack.com/block-kit-builder/

module AppStatusNotification
  module Notification
    class Slack < Adapter

      def initialize(options)
        @webhook_url = URI(options['webhook_url'])
        @token = options['token']
        @channel = options['channel']

        super
      end

      def send(message)
        data = if message.is_a?(String)
                  {
                    type: :mrkdwn,
                    text: message
                  }
                else
                  {
                    blocks: [
                      {
                        type: :section,
                        text: {
                          type: 'mrkdwn',
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
                      },
                    ]
                  }
                end

        response = Net::HTTP.post(@webhook_url,  data.to_json, 'Content-Type' => 'application/json')

        ap response.code
        ap response.body
      # rescue => e
      #   @exception = e
      #   nil
      end

      Notification.register self, :slack
    end
  end
end
