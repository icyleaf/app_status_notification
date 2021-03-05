require 'app_status_notification'
require 'app_status_notification/version'

require 'gli'

class AppStatusNotification::Command
  extend GLI::App

  program_desc 'Manage iOS app status notification'

  version AppStatusNotification::VERSION

  subcommand_option_handling :normal
  arguments :strict

  desc 'Enable development mode (use .local.yml config)'
  switch [:d, :development]

  desc 'Set log level'
  default_value 'info'
  arg_name 'value'
  flag [:'log-level']

  desc 'Set config file'
  arg_name 'config/notification.yml'
  flag [:c, :config]

  desc 'Start watch service'
  arg_name 'Describe arguments to ddd here'
  command :watch do |c|
    c.action do |global_options, options, args|
      AppStatusNotification.watch(global_options[:config])
    end
  end

  pre do |global,command,options,args|
    AppStatusNotification.development(global[:development])
    # Pre logic here
    # Return true to proceed; false to abort and not call the
    # chosen command
    # Use skips_pre before a command to skip this block
    # on that command only
    true
  end

  post do |global,command,options,args|
    # Post logic here
    # Use skips_post before a command to skip this
    # block on that command only
  end

  on_error do |exception|
    puts exception.backtrace
    # Error logic here
    # return false to skip default error handling
    true
  end

  default_command :watch
end
