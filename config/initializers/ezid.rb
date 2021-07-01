Ezid::Client.configure do |conf|
  conf.default_shoulder = 'ark:/99999/fk4' unless ENV['EZID_DEFAULT_SHOULDER']
  conf.user = 'apitest' unless ENV['EZID_USER']
  conf.password = File.exist?('/run/secrets/ezid_password') ? File.read('/run/secrets/ezid_password').strip : 'apitest'
end
