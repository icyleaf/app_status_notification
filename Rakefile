# frozen_string_literal: true


require 'pry-byebug'
require 'bundler/gem_tasks'
require 'app_status_notification'

require 'awesome_print'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

task(default: %i[spec rubocop])

Anyway::Settings.use_local_files = true
# ENV['ASN_PROXY'] = 'http://127.0.0.1:9999'

task :try do
  AppStatusNotification.watch
end

task :prerelease do
  config = AppStatusNotification::Config.new
  config.accounts.each do |account|
    account.apps.each do |app|
      context = AppStatusNotification::Runner::Context.new(account, app, config)
      client = context.client

      versions = client.builds(filter: {
        app: app.id,
      })
      ap versions
    end
  end
end

task :app do
  config = AppStatusNotification::Config.new
  config.accounts.each do |account|
    account.apps.each do |app|
      context = AppStatusNotification::Runner::Context.new(account, app, config)
      client = context.client

      edit_version = client.app_edit_version(id: app.id)
      latest_build = client.app_latest_build(id: app.id)
      ap latest_build

      build = client.update_appstore_version_build(version_id: edit_version.id, build_id: latest_build.id)
      # version = client.find_app_version(version: '4.15')
      # ap version
    end
  end
end

task :notifications do
  config = AppStatusNotification::Config.new(locale: 'en')

  messages = [
    {
      key: 'messages.app_version_created',
      app: 'App Status Notification',
      version: '6.0.0',
      status: 'Waiting for review'
    },
    {
      key: 'messages.app_build_received',
      app: 'App Status Notification',
      version: '6.0.0',
      build: '1.0'
    },
    {
      key: 'messages.prepare_appstoreversion_build',
      app: 'App Status Notification',
      version: '6.0.0',
      build: '1.0'
    },
    {
      key: 'messages.success_select_appstoreversion_build',
      app: 'App Status Notification',
      version: '6.0.0',
      build: '1.0'
    },
    {
      key: 'messages.success_select_appstoreversion_build',
      app: 'App Status Notification',
      version: '6.0.0',
      build: '1.0'
    },
    {
      key: 'messages.app_store_status_changes',
      app: 'App Status Notification',
      version: '6.0.0',
      status: 'Ready for sale'
    },
    {
      key: 'messages.app_was_on_sale',
      app: 'App Status Notification',
      version: '6.0.0'
    }
  ]

  # bot = AppStatusNotification::Notification::Slack.new(
  #   {
  #   'webhook_url' => 'https://hooks.slack.com/services/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'
  #   }
  # )

  bot = AppStatusNotification::Notification::Dingtalk.new(
    {
      'logger' => Logger.new(STDOUT),
      'webhook_url' => 'https://oapi.dingtalk.com/robot/send?access_token=3710070db4ac7e257012a494ed083d26e55fc34516adebedb90b9a7097b9785c',
      'secret' => 'SEC713673300a621e60dd7d0984061952a5389171e70663a536f5426b22b68cf5f0'
    }
  )

  messages.each do |message|
    bot.send(**message)
  end

  # bot = AppStatusNotification::Notification::WeCom.new(
  #   {
  #     'logger' => Logger.new(STDOUT),
  #     'webhook_url' => 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=0c9ff848-1396-4507-97da-8f97558b9f21',
  #   }
  # )
  # bot.send(**message)

  bot = AppStatusNotification::Notification::Feishu.new(
    {
      'logger' => Logger.new(STDOUT),
      'webhook_url' => 'https://open.feishu.cn/open-apis/bot/v2/hook/a4d69aa6-8532-447c-a649-eccbdede2f38',
      'secret' => 'XnZs2NbV4pndSVkCPFUvWb',
    }
  )
  bot.send(**message)
end


task :config do
  config = AppStatusNotification::Config.new
  ap config.to_filtered_h
end

version = AppStatusNotification::VERSION
registry = 'registry.cn-beijing.aliyuncs.com/hhz-tech/app_status_notification'

namespace :docker do
  task :all do
    Rake::Task['docker:build'].invoke
    Rake::Task['docker:publish'].invoke
  end

  task :build do
    puts "Building docker image ..."
    Rake::Task['install'].invoke
    `docker build \
      --build-arg APP_STATUS_NOTIFICATION_VERSION=#{version} \
      -t #{registry}:#{version} .`
  end

  task :publish do
    puts "Pushing docker image ..."
    `docker push #{registry}:#{version}`
  end

  task :run do
    `docker run -d -it \
      -v $(PWD)/config:/app/config \
      -v $(PWD)/stores:/app/stores \
      #{registry}:#{version}`
  end
end
