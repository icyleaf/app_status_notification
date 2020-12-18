# frozen_string_literal: true

require 'app_status_notification/connect_api/model'

module AppStatusNotification::ConnectAPI::Model
  class App
    include AppStatusNotification::ConnectAPI::Model

    attr_accessor :name
    attr_accessor :bundle_id
    attr_accessor :sku
    attr_accessor :primary_locale
    attr_accessor :is_opted_in_to_distribute_ios_app_on_mac_app_store
    attr_accessor :removed
    attr_accessor :is_aag
    attr_accessor :available_in_new_territories
    attr_accessor :content_rights_declaration

    # include
    attr_accessor :app_store_versions
    attr_accessor :builds

    def self.type
      'apps'
    end
  end
end
