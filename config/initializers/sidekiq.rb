Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] }
end

Sidekiq.logger.level = Logger::WARN
Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_key_base]
