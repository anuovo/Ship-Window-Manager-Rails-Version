require_relative "boot"

require "logger"
require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "sprockets/railtie"

Bundler.require(*Rails.groups)

module ShipWindowManager
  class Application < Rails::Application
    config.load_defaults 6.1
    config.time_zone = "Pacific Time (US & Canada)"
    config.active_record.schema_format = :ruby
    config.active_support.use_authenticated_message_encryption = false
    config.action_dispatch.use_authenticated_cookie_encryption = false
  end
end
