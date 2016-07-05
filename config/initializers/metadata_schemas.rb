MetadataSchema.configure do |config|
  fs_env_file = Rails.root.join("config", 'metadata_schema.yml')

  fail "Missing configuration file at: #{fs_env_file}." unless File.exist?(fs_env_file)

  begin
    fs_yml = YAML.load_file(fs_env_file)
  rescue StandardError
    raise("#{fs_env_file} was found, but could not be parsed.\n")
  end

  if File.exists?(fs_env_file)
    options = fs_yml.fetch(Rails.env).with_indifferent_access
    config.root_element_options = options.fetch(:root_element_options)
    config.parent_element_options = options.fetch(:parent_element_options)
    config.schema_terms = options.fetch(:schema_terms)
    config.canonical_identifier_path = options.fetch(:canonical_identifier_path)
    config.voyager_root = options.fetch(:voyager_root)
  end

end
