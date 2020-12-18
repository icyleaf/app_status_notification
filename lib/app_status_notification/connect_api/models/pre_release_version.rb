# frozen_string_literal: true

require 'app_status_notification/connect_api/model'

module AppStatusNotification::ConnectAPI::Model
  class PreReleaseVersion
    include AppStatusNotification::ConnectAPI::Model

    attr_accessor :version
    attr_accessor :platform

    def self.type
      return 'preReleaseVersions'
    end
  end
end
