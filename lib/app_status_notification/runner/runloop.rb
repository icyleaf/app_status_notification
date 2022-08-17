# frozen_string_literal: true

class AppStatusNotification::Runner
  module Runloop
    def runloop(&block)
      loop do
        # logger.debug store.to_h
        block.call
        wait_next_loop
      end
    end

    def wait_next_loop
      logger.debug t('logger.wait_next_loop', interval: config.refresh_interval)
      sleep config.refresh_interval
    end

    def capture_exception(exception)
      logger.error t('logger.raise_error', message: exception.full_message)
      logger.error exception.backtrace.join("\n")

      Sentry.capture_exception(exception) unless config.dry?
      raise exception
    end
  end
end
