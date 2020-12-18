# frozen_string_literal: true

require 'app_status_notification/error'
require 'app_status_notification/helper'
require 'app_status_notification/config'
require 'app_status_notification/store'
require 'app_status_notification/connect_api'
require 'app_status_notification/notification'
require 'app_status_notification/watchman'

module AppStatusNotification
  def self.run(config_file = nil)
    AppStatusNotification::Watchman.run(config_file)
  end
end
