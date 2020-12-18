# frozen_string_literal: true

require 'forwardable'

module AppStatusNotification
  class Runner
    include AppStatusNotification::I18nHelper

    extend Forwardable

    attr_reader :context

    def initialize(context)
      @context = context
    end

    def_delegators :@context, :config, :client
    def_delegators :config, :logger

    def start
      find_app
      start_work
    rescue Interrupt
      logger.info t('logger.interrupt')
      exit
    rescue => e
      Raven.capture_exception(e)

      logger.error t('logger.raise_error', message: e.full_message)
      wait_next_loop
      retry
    end

    def start_work
      runloop do
        edit_version = get_edit_version
        next if not_found_edit_version(edit_version)

        # 预检查提交版本是否真的存在
        review_version = edit_version.version_string
        next unless review_version

        review_status = edit_version.app_store_state
        check_app_store_version_changes(review_version, review_status)
        app_store_status_changes_notification(edit_version)

        return unless edit_version.editable?

        check_selected_build_changes(edit_version)
        build_processing_changes_notification(edit_version)
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
      send_notifications(
        key: 'messages.app_build_removed',
        app: app.name,
        version: edit_version.version_string,
        build: cached_selected_build
      )
    end

    # 检查构建版本状态后（成功、失败）通知
    def build_processing_changes_notification(edit_version)
      # 获取最新上传的构建版本

      latest_build = get_app_latest_build
      return if latest_build.nil?

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

      selected_build_notification(edit_version, latest_build)
    end

    def same_selected_build?(selected_build, latest_build)
      return false unless selected_build

      is_same = selected_build.version == latest_build.version
      if is_same && !store.selected_build
        store.selected_build = selected_build.version
        store.delete :unselected_build

        send_notifications(
          key: 'messages.select_appstoreversion_build_from_another_source',
          app: app.name,
          version: store.version,
          build: selected_build.version
        )
      end

      is_same
    end

    # 处理选中构建版本
    def selected_build_notification(edit_version, latest_build)
      cached_selected_build = store.selected_build
      selected_build = edit_version.build

      # 没有缓存和已经选中构建版本，尝试选中最新上传版本
      if cached_selected_build.nil? && selected_build.nil?
        return select_version_build(edit_version, latest_build)
      end

      # 发现选中版本写入缓存并发通知
      if selected_build && !cached_selected_build
        store.selected_build = selected_build.version
        return send_notifications(
          key: 'messages.app_build_processed',
          app: app.name,
          version: release_version,
          build: edit_version.version
        )
      end

      # 没有选中版本可能是网页上被删除选中
      return unless selected_build

      # 发现选择版本一样跳过
      return if cached_selected_build == selected_build.version || selected_build.version == latest_build.version

      # 选中构建版本和最新上传构建版本不一致通知
      store.selected_build = selected_build.version
      send_notifications(
        key: 'messages.app_build_changed',
        app: app.name,
        version: release_version,
        old_build: cached_selected_build,
        new_build: selected_build.version
      )
    end

    def select_version_build(edit_version, build)
      # 如果曾经选中被移除不再重新选中
      return if store.unselected_build == build.version

      send_notifications(
        key: 'messages.prepare_appstoreversion_build',
        app: app.name,
        version: edit_version.version_string,
        build: build.version
      )

      r = client.select_version_build(edit_version.id, build_id: build.id)
      if r.status == 204
        store.selected_build = build.version
        send_notifications(
          key: 'messages.success_select_appstoreversion_build',
          app: app.name,
          version: edit_version.version_string,
          build: build.version
        )
      else
        send_notifications(
          key: 'messages.failed_select_appstoreversion_build',
          app: app.name,
          version: edit_version.version_string,
          build: build.version
        )
      end
    end

    def cached_latest_build?(version, build)
      return true if store.version == version && store.latest_build == build.version

      store.latest_build = build.version
      false
    end

    # 没有找到新建版本的审核
    def not_found_edit_version(edit_version)
      return if edit_version

      live_version = get_live_version
      logger.debug t('logger.not_found_edit_version', version: live_version.version_string)

      app_on_sale_with_uncatch_process_notification(live_version)

      store.clear
      logger.debug t('logger.wait_next_loop', interval: config.refresh_interval)
      true
    end

    def app_on_sale_with_uncatch_process_notification(live_version)
      if (cache_version = store.version) &&
        Gem::Version.new(live_version.version_string) >= Gem::Version.new(cache_version)

        # TODO: 审核的版本已经发布发送通知
        send_notifications(
          key: 'app_was_on_sale',
          app: app.name,
          version: live_version.version_string
        )
      end
    end

    # 检查编辑版本号是否发生变化
    def check_app_store_version_changes(version, status)
      cached_version = store.version
      store.version = version

      status_text = t("app_store_status.#{status.downcase}")
      if cached_version.to_s.empty?
        store.status = status

        send_notifications(
          key: 'messages.app_version_created',
          app: app.name,
          version: version,
          status: status_text
        )
      elsif cached_version != version
        send_notifications(
          key: 'messages.app_version_changed',
          app: app.name,
          current_version: cached_version,
          new_version: version,
          status: status_text
        )
      end
    end

    # 状态变更的通知
    def app_store_status_changes_notification(edit_version)
      status = edit_version.app_store_state
      version = edit_version.version_string
      return if status == store.status

      logger.info "#{app.name} v#{version} changed status to `#{status}` created at #{edit_version.created_date}"

      store.status = status
      status_text = t("app_store_status.#{status.downcase}")
      todo_text = t("todo.#{status.downcase}")
      message = if I18n.exists?(:"todo.#{status.downcase}")
        {
          key: 'messages.app_store_status_changes_with_todo',
          app: app.name,
          version: version,
          status: status_text,
          todo: todo_text
        }
      else
        {
          key: 'messages.app_store_status_changes',
          app: app.name,
          version: version,
          status: status_text
        }
      end

      send_notifications(message)
    end


    #####################
    # Notifcations
    #####################

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

    def send_notifications(message)
      return unless message

      allowed_notifications = context.app.notifications

      config.notifications.each do |nname, nargs|
        next unless allowed_notifications.size == 0 ||
                    allowed_notifications.include?(nname)

        logger.debug t('logger.send_notification', name: nname, message: t(message))
        Notification.send(message, nargs) unless config.dry?
      end
    end

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

    def get_edit_version
      version = client.app_edit_version(app.id)
      logger.debug "API Rate: #{version.rate}"
      version
    end

    def get_live_version
      client.app_live_version(app.id)
    end

    #####################
    # Build
    #####################

    def get_app_latest_build
      client.app_latest_build(app.id)
    end

    #####################
    # Internal
    #####################

    def find_app
      logger.info t('logger.found_app', name: app.name, id: app.id, bundle_id: app.bundle_id)
    end

    def store
      @store ||= Store.new context.app.id, config.store_path
    end

    def runloop(&block)
      loop do
        logger.debug store.to_h
        block.call
        wait_next_loop
      end
    end

    def wait_next_loop
      logger.debug t('logger.wait_next_loop', interval: config.refresh_interval)
      sleep config.refresh_interval
    end

    class Context
      extend Forwardable

      attr_reader :app, :config

      def initialize(account, app, config)
        @account = account
        @app = app
        @config = config
      end

      def client
        @client ||= ConnectAPI.from_context(self)
      end

      def_delegators :@account, :issuer_id, :key_id, :private_key
    end
  end
end
