
if Rails.env.production?
  Honeybadger.configure do |config|
    config.api_key = File.read('/run/secrets/honeybadger_api_key').strip
  end
end
