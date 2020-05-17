# frozen_string_literal: true

load File.expand_path '../production.rb', __FILE__
require 'rack/remember_uuid'
require 'syslog/logger'

Rails.application.configure do
  config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new('conjur-possum'))

  # we log our log messages (CONJ) in INFO to split them from the DB messages that
  # are written in DEBUG. Thus, the default value should be 'warn'
  config.log_level = ENV['CONJUR_LOG_LEVEL'] || :warn

  config.middleware.use Rack::RememberUuid
  config.audit_socket = '/run/conjur/audit.socket'
  config.audit_database ||= 'postgres://:5433/audit'
end
