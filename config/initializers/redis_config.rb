require 'redis'

config_file = Rails.root.join("config", 'redis.yml')
fail "Missing configuration file at: #{config_file}." unless File.exist?(config_file)

config = YAML.load(ERB.new(File.read(config_file)).result)[Rails.env]

Redis.current = Redis.new(config.merge(thread_safe: true))
