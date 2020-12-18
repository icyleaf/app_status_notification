# frozen_string_literal: true

require 'app_status_notification/connect_api/model'

module AppStatusNotification::ConnectAPI::Model
  class AppStoreVersion
    include AppStatusNotification::ConnectAPI::Model

    attr_accessor :platform
    attr_accessor :version_string
    attr_accessor :app_store_state
    attr_accessor :release_type
    attr_accessor :earliest_release_date # 2020-06-17T12:00:00-07:00
    attr_accessor :uses_idfa
    attr_accessor :downloadable
    attr_accessor :created_date
    attr_accessor :version
    attr_accessor :uploaded_date
    attr_accessor :expiration_date
    attr_accessor :expired
    attr_accessor :store_icon
    attr_accessor :watch_store_icon
    attr_accessor :copyright
    attr_accessor :min_os_version

    # include
    attr_accessor :app
    attr_accessor :app_store_version_submission
    attr_accessor :build

    ESSENTIAL_INCLUDES = [
      'app',
      'appStoreVersionSubmission',
      'build'
    ].join(',')

    module AppStoreState
      READY_FOR_SALE = 'READY_FOR_SALE'
      PROCESSING_FOR_APP_STORE = 'PROCESSING_FOR_APP_STORE'
      PENDING_DEVELOPER_RELEASE = 'PENDING_DEVELOPER_RELEASE'
      IN_REVIEW = 'IN_REVIEW'
      WAITING_FOR_REVIEW = 'WAITING_FOR_REVIEW'
      DEVELOPER_REJECTED = 'DEVELOPER_REJECTED'
      REJECTED = 'REJECTED'
      PREPARE_FOR_SUBMISSION = 'PREPARE_FOR_SUBMISSION'
      METADATA_REJECTED = 'METADATA_REJECTED'
      INVALID_BINARY = 'INVALID_BINARY'
    end

    module ReleaseType
      AFTER_APPROVAL = 'AFTER_APPROVAL'
      MANUAL = 'MANUAL'
      SCHEDULED = 'SCHEDULED'
    end

    def self.type
      'appStoreVersions'
    end

    def on_sale?
      app_store_state == AppStoreState::READY_FOR_SALE ||
      app_store_state == AppStoreState::PROCESSING_FOR_APP_STORE
    end

    def in_review?
      app_store_state == AppStoreState::IN_REVIEW
    end

    def preparing?
      app_store_state == AppStoreState::PREPARE_FOR_SUBMISSION ||
      app_store_state == AppStoreState::DEVELOPER_REJECTED
    end

    def rejected?
      app_store_state == AppStoreState::REJECTED ||
      app_store_state == AppStoreState::METADATA_REJECTED ||
      app_store_state == AppStoreState::INVALID_BINARY
    end

    def editable?
      preparing? || rejected?
    end
  end
end
