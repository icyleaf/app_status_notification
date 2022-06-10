# frozen_string_literal: true

require 'forwardable'
require 'app_status_notification/runner/context'
require 'app_status_notification/runner/runloop'
require 'app_status_notification/runner/variables'
require 'app_status_notification/runner/notification'

module AppStatusNotification
  class Runner
    extend Forwardable

    include AppStatusNotification::I18nHelper
    include AppStatusNotification::Runner::Variables
    include AppStatusNotification::Runner::Notification
    include AppStatusNotification::Runner::Runloop

    attr_reader :context

    def initialize(context)
      @context = context
      determine_notification!
    end

    def_delegators :@context, :config, :client
    def_delegators :config, :logger

    def start
      find_app
      config.test_mode ? start_test : start_work
    rescue Interrupt
      logger.info t('logger.interrupt')
      exit
    rescue Faraday::ConnectionFailed
      logger.info t('logger.connection_failed')
      retry
    rescue => exception
      capture_exception(exception)

      wait_next_loop
      retry
    end

    def start_test
      test_notification(app)
    end

    def start_work
      runloop do
        version = edit_version
        next if not_found_edit_version(version)

        # 预检查提交版本是否真的存在
        review_version = version.version_string
        next unless review_version

        review_status = version.app_store_state
        check_app_store_version_changes(review_version, review_status)
        app_store_status_changes_notification(version)

        next unless version.editable?

        check_selected_build_changes(version)
        build_processing_changes(version)
      end
    end

    private

    # 检查之前选中但被网页上人工取消该版本就发出通知
    def check_selected_build_changes(edit_version)
      cached_selected_build = store.selected_build
      selected_build = edit_version.build
      return unless cached_selected_build && !selected_build

      store.unselected_build = cached_selected_build
      store.delete :selected_build
      app_build_removed_notification(app, edit_version, cached_selected_build)
    end

    # 检查构建版本状态后（成功、失败）通知
    def build_processing_changes(edit_version)
      # 获取最新上传的构建版本

      latest_build = app_latest_build
      return if latest_build.nil?

      # 检查 build 的 app 版本是否和当前审核版本一致
      return if latest_build.pre_release_version.version != edit_version.version_string

      # 检查选中版本是否是最新版本
      return if same_selected_build?(edit_version.build, latest_build)

      review_version = edit_version.version_string
      unless cached_latest_build?(review_version, latest_build)
        case latest_build.processing_state
        when ConnectAPI::ProcessStatus::PROCESSING
          build_received_notification(review_version, latest_build)
        when ConnectAPI::ProcessStatus::VALID
          build_processed_notification(review_version, latest_build)
        else
          build_failed_notification(review_version, latest_build)
        end
      end

      # 如果构建版本正在处理中不做处理
      return if latest_build.processing_state == ConnectAPI::ProcessStatus::PROCESSING

      selected_build_notification(edit_version, latest_build)
    end

    def same_selected_build?(selected_build, latest_build)
      return false unless selected_build

      is_same = selected_build.version == latest_build.version
      if is_same && !store.selected_build
        store.selected_build = selected_build.version
        store.delete :unselected_build

        app_build_selected_from_another_source_notification(app, store, selected_build)
      end

      is_same
    end

    # 处理选中构建版本
    def selected_build_notification(edit_version, latest_build)
      cached_selected_build = store.selected_build
      selected_build = edit_version.build

      # 没有缓存和已经选中构建版本，尝试选中最新上传版本
      return select_version_build(edit_version, latest_build) if cached_selected_build.nil? && selected_build.nil?

      # 发现选中版本写入缓存并发通知
      if selected_build && !cached_selected_build
        store.selected_build = selected_build.version
        return app_build_processed_notification(app, release_version, edit_version)
      end

      # 没有选中版本可能是网页上被删除选中
      return unless selected_build

      # 发现选择版本一样跳过
      return if cached_selected_build == selected_build.version || selected_build.version == latest_build.version

      # 选中构建版本和最新上传构建版本不一致通知
      store.selected_build = selected_build.version
      app_build_changed_notification(app, release_version, cached_selected_build, selected_build)
    end

    def select_version_build(edit_version, build)
      # 如果曾经选中被移除不再重新选中
      return if store.unselected_build == build.version

      prepare_appstoreversion_build_notification(app, edit_version, build)
      select_app_build(edit_version, build)
    end

    def select_app_build(edit_version, build)
      r = client.select_version_build(edit_version.id, build_id: build.id)
      if r.status == 204
        suceess_selected_build_notification(edit_version.version_string, build)
      else
        fail_selected_build_notification(edit_version.version_string, build)
      end
    rescue ConnectAPIError => e
      logger.error("[#{e.class}]: #{e.full_message}")
      fail_selected_build_notification(edit_version.version_string, build)
    end

    def cached_latest_build?(version, build)
      return true if store.version == version && store.latest_build == build.version

      store.latest_build = build.version
      false
    end

    # 没有找到新建版本的审核
    def not_found_edit_version(edit_version)
      return if edit_version

      version = live_version
      logger.debug t('logger.not_found_edit_version', version: version.version_string)

      app_on_sale_with_uncatch_process_notification(version)
      store.clear

      true
    end

    # 检查编辑版本号是否发生变化
    def check_app_store_version_changes(version, status)
      cached_version = store.version
      status_text = t("app_store_status.#{status.downcase}")
      if cached_version.to_s.empty?
        store.version = version
        store.status = status
        app_version_created_notification(app, version, status_text)
      elsif cached_version != version
        app_version_changed_notification(app, version, cached_version, status_text)
      end
    end

    #####################
    # Internal
    #####################

    def determine_notification!
      global_notifications = config.notifications
      app_notifications = context.app.notifications
      enabled_notifications = app_notifications.empty? ? global_notifications.keys : app_notifications
      logger.info t('logger.enabled_notification',
                    count: enabled_notifications.size,
                    notifications: enabled_notifications.join(', ')
                  )
    end

    def find_app
      logger.info t('logger.found_app', name: app.name, id: app.id, bundle_id: app.bundle_id)
    end
  end
end
