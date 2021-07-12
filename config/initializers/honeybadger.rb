# Adding Honeybadger configuration.

if !Rails.env.test? && !Rails.env.development? && File.exist?('/run/secrets/honeybadger_api_key')
  Honeybadger.configure do |config|
    config.api_key = File.read('/run/secrets/honeybadger_api_key').strip
  end
end
