# Adding Honeybadger configuration.

if Rails.env.production? && File.exist?('/run/secrets/honeybadger_api_key')
  Honeybadger.configure do |config|
    config.api_key = File.read('/run/secrets/honeybadger_api_key').strip
  end
end
