module FileExtensions
  def config
    @config ||= config_yaml.with_indifferent_access
  end

  def asset_file_extensions
    return load_extensions("assets")
  end

  def metadata_source_file_extensions
    return load_extensions("metadata_sources")
  end


  private

    def config_yaml
      config_file = Rails.root.join("config", 'file_extensions.yml')
      fail "Missing configuration file at: #{config_file}." unless File.exist?(config_file)
      YAML.load(ERB.new(File.read(config_file)).result)[Rails.env]
    end

    def load_extensions(exts_type)
      file_extensions = FileExtensions.config[:allowed_extensions]["#{exts_type.to_sym}"].split(",")
      return file_extensions
    end

    module_function :config, :config_yaml, :asset_file_extensions, :metadata_source_file_extensions, :load_extensions
    
end
