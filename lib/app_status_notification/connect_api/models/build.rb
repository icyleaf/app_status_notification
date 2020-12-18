# frozen_string_literal: true

require 'app_status_notification/connect_api/model'

module AppStatusNotification::ConnectAPI::Model
  class Build
    include AppStatusNotification::ConnectAPI::Model

    attr_accessor :version
    attr_accessor :uploaded_date
    attr_accessor :expiration_date
    attr_accessor :expired
    attr_accessor :min_os_version
    attr_accessor :icon_asset_token
    attr_accessor :processing_state
    attr_accessor :uses_non_exempt_encryption

    attr_accessor :app
    attr_accessor :beta_app_review_submission
    attr_accessor :beta_build_metrics
    attr_accessor :build_beta_detail
    attr_accessor :pre_release_version

    ESSENTIAL_INCLUDES = 'app,preReleaseVersion'

    def self.type
      'builds'
    end
  end
end
