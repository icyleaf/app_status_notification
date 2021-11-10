# frozen_string_literal: true

require 'forwardable'

class AppStatusNotification::Runner
  module Notification
    # 构建版本已经被取消勾选
    def app_build_removed_notification(app, edit_version, cached_selected_build)
      send_notifications(
        key: 'messages.app_build_removed',
        app: app.name,
        version: edit_version.version_string,
        build: cached_selected_build
      )
    end

    # 构建版本从其他途径被勾选
    def app_build_selected_from_another_source_notification(app, store, selected_build)
      send_notifications(
        key: 'messages.select_appstoreversion_build_from_another_source',
        app: app.name,
        version: store.version,
        build: selected_build.version
      )
    end

    def app_build_processed_notification(app, release_version, edit_version)
      send_notifications(
        key: 'messages.app_build_processed',
        app: app.name,
        version: release_version,
        build: edit_version.version
      )
    end

    def app_build_changed_notification(app, release_version, cached_selected_build, selected_build)
      send_notifications(
        key: 'messages.app_build_changed',
        app: app.name,
        version: release_version,
        old_build: cached_selected_build,
        new_build: selected_build.version
      )
    end

    def prepare_appstoreversion_build_notification(app, edit_version, build)
      send_notifications(
        key: 'messages.prepare_appstoreversion_build',
        app: app.name,
        version: edit_version.version_string,
        build: build.version
      )
    end

    def app_on_sale_notification(app, live_version)
      send_notifications(
        key: 'messages.app_was_on_sale',
        app: app.name,
        version: live_version.version_string
      )
    end

    def app_version_created_notification(app, version, status_text)
      send_notifications(
        key: 'messages.app_version_created',
        app: app.name,
        version: version,
        status: status_text
      )
    end

    def app_version_changed_notification(app, version, cached_version, status_text)
      send_notifications(
        key: 'messages.app_version_changed',
        app: app.name,
        current_version: cached_version,
        new_version: version,
        status: status_text
      )
    end

    def app_store_status_changed_notification(app, version, status)
      message = {
        key: 'messages.app_store_status_changes',
        app: app.name,
        version: version,
        status: t("app_store_status.#{status.downcase}")
      }

      if todo = t("todo.#{status.downcase}", default: nil)
        message[:key] = 'messages.app_store_status_changes_with_todo'
        message[:todo] = todo
      end

      send_notifications(message)
    end

    def app_on_sale_with_uncatch_process_notification(live_version)
      if (cache_version = store.version) &&
        Gem::Version.new(live_version.version_string) >= Gem::Version.new(cache_version)
        app_on_sale_notification(app, live_version)
      end
    end

    # 状态变更的通知
    def app_store_status_changes_notification(edit_version)
      status = edit_version.app_store_state
      version = edit_version.version_string
      return if status == store.status

      logger.info "#{app.name} v#{version} changed status to `#{status}` created at #{edit_version.created_date}"
      store.status = status
      app_store_status_changed_notification(app, version, status)
    end

    # 成功自动勾选最新上传的构建版本通知
    def suceess_selected_build_notification(version, build)
      store.selected_build = build.version
      send_notifications(
        key: 'messages.success_select_appstoreversion_build',
        app: app.name,
        version: version,
        build: build.version
      )
    end

    # 失败自动勾选最新上传的构建版本通知
    def fail_selected_build_notification(version, build)
      store.unselected_build = build.version
      send_notifications(
        key: 'messages.failed_select_appstoreversion_build',
        app: app.name,
        version: version,
        build: build.version
      )
    end

    # 发出接收到构建版本通知
    def build_received_notification(version, build)
      send_notifications(
        key: 'messages.app_build_received',
        app: app.name,
        version: version,
        build: build.version
      )
    end

    # 发出处理完毕构建版本通知
    def build_processed_notification(version, build)
      send_notifications(
        key: 'messages.app_build_processed',
        app: app.name,
        version: version,
        build: build.version
      )
    end

    # 发出构建版本处理失败、无效通知
    def build_failed_notification(version, build)
      send_notifications(
        key: 'messages.app_build_failed',
        app: app.name,
        version: version,
        build: build.version,
        status: build.processing_state
      )
    end

    def test_notification(app)
      send_notifications(
        key: 'messages.test',
        name: app.name
      )
    end

    def send_notifications(message)
      return unless message

      allowed_notifications = context.app.notifications

      config.notifications.each do |nname, nargs|
        next unless allowed_notifications.size == 0 ||
                    allowed_notifications.include?(nname)

        logger.debug t('logger.send_notification', name: nname, message: t(**message))
        nargs['logger'] = logger
        AppStatusNotification::Notification.send(message, nargs) unless config.dry?
      end
    end
  end
end
