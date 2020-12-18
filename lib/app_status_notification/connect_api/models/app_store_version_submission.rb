# frozen_string_literal: true

require 'app_status_notification/connect_api/model'

module AppStatusNotification::ConnectAPI::Model
  class AppStoreVersionSubmission
    include AppStatusNotification::ConnectAPI::Model

    attr_accessor :can_reject

    def self.type
      'appStoreVersionSubmissions'
    end
  end
end
