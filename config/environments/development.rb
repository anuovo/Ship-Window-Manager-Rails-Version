Rails.application.configure do
  config.secret_key_base = ENV.fetch("SECRET_KEY_BASE", "development-secret-key-base-for-ship-window-manager-local-only")
  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.active_storage.service = :local if config.respond_to?(:active_storage)
  config.assets.debug = true
  config.assets.quiet = true
end
