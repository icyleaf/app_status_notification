# frozen_string_literal: true

require 'active_support/cache'
require 'forwardable'

module AppStatusNotification
  class Store
    extend Forwardable

    ALLOWED_KEYS = %i[version status latest_build selected_build unselected_build]

    def_delegators :@cache, :read, :write, :delete, :clear

    attr_reader :app_id

    def initialize(app_id, path)
      @cache = ActiveSupport::Cache::FileStore.new(File.join(path, app_id.to_s))

      configure!
    end

    def fetch(key, default_value)
      @cache.fetch(key, force: true) { default_value }
    end

    def [](key)
      @cache.read(key)
    end

    def []=(key, value)
      @cache.write(key, value)
    end

    def to_h
      ALLOWED_KEYS.each_with_object({}) do |key, obj|
        obj[key] = @cache.read(key)
      end
    end

    def method_missing(method_name, *kwargs)
      allowed, key, write_mode = allowed_key?(method_name)
      super unless allowed

      write_mode ? @cache.write(key, kwargs.first) : @cache.read(key)
    end

    def respond_to_missing?(method_name, include_private = false)
      allowed, _ = allowed_key?(method_name)
      allowed || super
    end

    def configure!
      ALLOWED_KEYS.each do |key|
        @cache.fetch(key, nil)
      end
    end

    private

    def allowed_key?(key)
      key = key.to_s
      write_mode = key.end_with?('=')
      key = key[0..-2] if write_mode
      key = key.to_sym
      [ALLOWED_KEYS.include?(key), key, write_mode]
    end
  end
end
