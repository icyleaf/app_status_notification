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

  desc 'Set config path'
  arg_name 'config'
  flag [:c, :config]

  desc 'Set store path'
  arg_name 'store'
  flag [:s, :store]

  desc 'Start watch service'
  arg_name 'Describe arguments to ddd here'
  command :watch do |c|
    c.action do |global, options, args|
      AppStatusNotification.watch(global[:config], global[:store])
    end
  end

  pre do |global, command, options, args|
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
    # puts exception.backtrace unless exception.is_a?(Interrupt)
    # Error logic here
    # return false to skip default error handling
    exception.is_a?(SystemExit) ? false : true
  end

  default_command :watch
end
