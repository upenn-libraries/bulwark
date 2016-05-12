module FileExtensions

  def asset_file_extensions
    extensions_yml = "#{Rails.root}/config/file_extensions.yml"
    extensions_config = YAML.load_file(File.expand_path(extensions_yml, __FILE__))
    asset_file_extensions = extensions_config["#{Rails.env}"]["allowed_extensions"]["assets"].split(",")
    return asset_file_extensions
  end

  def metadata_source_file_extensions
    extensions_yml = "#{Rails.root}/config/file_extensions.yml"
    extensions_config = YAML.load_file(File.expand_path(extensions_yml, __FILE__))
    metadata_source_file_extensions = extensions_config["#{Rails.env}"]["allowed_extensions"]["metadata_sources"].split(",")
    return metadata_source_file_extensions
  end

end
