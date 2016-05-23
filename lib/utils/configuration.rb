module Utils
  class Configuration
    attr_accessor :object_data_path
    attr_accessor :object_admin_path
    attr_accessor :object_derivatives_path
    attr_accessor :object_semantics_location
    attr_accessor :email
    attr_accessor :assets_path
    attr_accessor :assets_display_path
    attr_accessor :manifest_location
    attr_accessor :federated_fs_path
    attr_accessor :metadata_path_label
    attr_accessor :file_path_label
    attr_accessor :imports_local_staging
    attr_accessor :transformed_dir
    attr_accessor :working_dir
    attr_accessor :repository_prefix
    attr_accessor :split_on
  end
end
