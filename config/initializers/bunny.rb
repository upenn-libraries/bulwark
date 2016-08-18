Bunny.configure do |config|
  fs_env_file = Rails.root.join("config", 'bunny.yml')

  fail "Missing configuration file at: #{fs_env_file}." unless File.exist?(fs_env_file)

  begin
    fs_yml = YAML.load_file(fs_env_file)
  rescue StandardError
    raise("#{fs_env_file} was found, but could not be parsed.\n")
  end

  if File.exists?(fs_env_file)
    options = fs_yml.fetch(Rails.env).with_indifferent_access
  end

end
