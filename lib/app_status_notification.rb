# frozen_string_literal: true

require 'tiny_appstore_connect'
require 'app_status_notification/error'
require 'app_status_notification/helper'
require 'app_status_notification/config'
require 'app_status_notification/store'
require 'app_status_notification/notification'
require 'app_status_notification/watchman'
require 'app_status_notification/command'

module AppStatusNotification
  def self.run(params = ARGV)
    AppStatusNotification::Command.run(params)
  end

  def self.watch(config_path = nil, store_path = nil, test_mode: false)
    AppStatusNotification::Watchman.run(config_path, store_path, test_mode: test_mode)
  end

  def self.development(enabled = false)
    Anyway::Settings.use_local_files = !!enabled
  end
end
