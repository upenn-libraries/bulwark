module AutomatedWorkflows
  class Constants
    DEFAULTS = {}

    DEFAULTS['default'] = { :human_readable_name => 'no_name',
                            :metadata_subdirectory => 'metadata',
                            :assets_subdirectory => 'assets',
                            :file_extensions => ['tif', 'TIF'],
                            :metadata_source_extensions => ['xlsx'],
                            :preservation_filename => 'preservation.xml',
    }
    DEFAULTS['directory'] = { :human_readable_name => 'directory_no_name',
                              :metadata_subdirectory => 'metadata',
                              :assets_subdirectory => 'assets',
                              :file_extensions => ['tif', 'TIF', 'jpeg'],
                              :metadata_source_extensions => ['xlsx'],
                              :preservation_filename => 'preservation.xml'
    }
  end
end
