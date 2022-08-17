# frozen_string_literal: true

class AppStatusNotification::Runner
  module Variables
    #####################
    # App
    #####################

    # 获得当前 app 信息
    def app
      @app ||= client.app(context.app.id)
    end

    #####################
    # Version
    #####################

    def edit_version
      version = client.app_edit_version(app.id)
      logger.debug "API Rate: #{version.rate}" if version
      version
    end

    def live_version
      client.app_live_version(app.id)
    end

    #####################
    # Build
    #####################

    def app_latest_build
      client.app_latest_build(app.id)
    end

    def store
      @store ||= AppStatusNotification::Store.new(
        context.app.id, config.store_path,
        logger: context.config.logger
      )
    end
  end
end
