module FileExtensions

  def asset_file_extensions
    return load_extensions("assets")
  end

  def metadata_source_file_extensions
    return load_extensions("metadata_sources")
  end

  def load_extensions(exts_type)
    file_extensions = FileExtensions.config[:allowed_extensions]["#{exts_type.to_sym}"].split(",")
    return file_extensions
  end

end
