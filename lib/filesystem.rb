module Filesystem
    def assets_path_prefix
      filesystem_yml = "#{Rails.root}/config/filesystem.yml"
      fs_config = YAML.load_file(File.expand_path(filesystem_yml, __FILE__))
      assets_path_prefix = fs_config["#{Rails.env}"]["assets_path"]
      return assets_path_prefix
    end
end
