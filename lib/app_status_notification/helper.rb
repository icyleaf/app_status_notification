# frozen_string_literal: true

require 'i18n'

module AppStatusNotification
  module I18nHelper
    def t(key = nil, **kargs)
      key ||= kargs.delete(:key)
      raise 'No found key of i18n' if key.to_s.empty?

      unless I18n.exists?(key)
        return kargs.include?(:default) ? kargs[:default] : key
      end

      I18n.t(key.to_sym, **kargs)
    end
  end
end
