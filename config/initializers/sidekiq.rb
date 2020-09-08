Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] }
end

Sidekiq.logger.level = Logger::WARN

Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_key_base]
Sidekiq::Web.set :sessions, Rails.application.config.session_options

# Add scheduled jobs
if Sidekiq.server?
  # Every day at 1am remove searches that are older than 7 days.
  Sidekiq::Cron::Job.create(
    name: 'Delete Old Searches (Daily)',
    cron: '0 1 * * *',
    class: 'Maintenance::DeleteSearches',
    queue: 'maintenance'
  )
end
