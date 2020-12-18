# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'app_status_notification/version'

Gem::Specification.new do |spec|
  spec.name          = 'app_status_notification'
  spec.version       = AppStatusNotification::VERSION
  spec.authors       = ['icyleaf']
  spec.email         = ['icyleaf.cn@gmail.com']

  spec.summary       = 'Get those App Store Connect notifications delivered directly to Slack.'
  spec.homepage      = 'https://github.com/icyleaf/app_status_notification'
  spec.license       = 'MIT'

  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.require_paths = ['lib']

  spec.add_dependency 'faraday', '>= 1.0.1'
  spec.add_dependency 'faraday_middleware', '>= 1.0.0'
  spec.add_dependency 'jwt', '>= 1.4', '<= 2.2.1'
  spec.add_dependency 'anyway_config', '>= 2.0.0'
  spec.add_dependency 'activesupport', '>= 6.0.3.1'
  spec.add_dependency 'i18n', '~> 1.8.5'
  spec.add_dependency 'sentry-raven'

  spec.add_development_dependency 'awesome_print', '~> 2.0.0.pre2'
  spec.add_development_dependency 'bundler', '~> 2.1'
  # spec.add_development_dependency 'factory_bot', '~> 5.0.2'
  # spec.add_development_dependency 'guard-rspec', '~> 4.7.3'
  spec.add_development_dependency 'pry-byebug', '~> 3.9.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.10'
  spec.add_development_dependency 'rubocop', '~> 1.1.0'
  # spec.add_development_dependency 'semantic', '~> 1.5'
  # spec.add_development_dependency 'simplecov', '~> 0.16.1'
  # spec.add_development_dependency 'timecop', '~> 0.9.1'
  # spec.add_development_dependency 'webmock', '~> 3.6.0'
end
