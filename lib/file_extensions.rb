module FileExtensions

  def asset_file_extensions
    return load_extensions("assets")
  end

  def metadata_source_file_extensions
    return load_extensions("metadata_sources")
  end

  def load_extensions(exts_type)
    extensions_yml = "#{Rails.root}/config/file_extensions.yml"
    extensions_config = YAML.load_file(File.expand_path(extensions_yml, __FILE__))
    file_extensions = extensions_config["#{Rails.env}"]["allowed_extensions"]["#{exts_type}"].split(",")
    return file_extensions
  end

end
