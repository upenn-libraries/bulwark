require Rails.root.join('lib', 'rails_admin', 'git_actions.rb')
require Rails.root.join('lib', 'rails_admin', 'create_remote.rb')
require Rails.root.join('lib', 'rails_admin', 'clone_from_production.rb')
require Rails.root.join('lib', 'rails_admin', 'sign_off_production.rb')
require Rails.root.join('lib', 'rails_admin', 'report_flagged.rb')
require Rails.root.join('lib', 'rails_admin', 'ingest.rb')
require Rails.root.join('lib', 'rails_admin', 'generate_metadata.rb')
require Rails.root.join('lib', 'rails_admin', 'preview_xml.rb')
require Rails.root.join('lib', 'rails_admin', 'preserve.rb')

RailsAdmin.config do |config|
  config.main_app_name = ["Review", "Admin Dashboard"]

  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  config.navigation_static_links = {
    "Front End" => "/"
  }

  config.included_models = ["Repo"]

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new do
      only ["Repo"]
    end
    git_actions do
      only ["Repo"]
    end
    preserve do
      only ["Repo"]
    end
    generate_metadata
    preview_xml
    create_remote do
      only ["Repo"]
    end
    ingest do
      only ["Repo"]
    end
    edit
    delete
  end

  config.model Repo do
    field :title do
      required(true)
    end
    field :directory_link do
      visible false
      label "Directory"
      pretty_value do
        %{#{value}}.html_safe
      end
    end
    field :directory do
      required(true)
      help "Required - directory on the remote filesystem that will serve as the location for the git repository"
    end
    field :description do
      required(false)
    end
    field :metadata_subdirectory do
      required(true)
      help "Required - subdirectory within the directory specified above that will serve as the location for the metadata to be processed by the application"
    end
    field :assets_subdirectory do
      required(true)
      help "Required - subdirectory within the directory specified above that will serve as the location for the assets to be processed by the application"
    end
    field :file_extensions, :enum do
      required(true)
      enum_method do
        :load_file_extensions
      end
      multiple do
        true
      end
      help "Required - comma-separated list of accepted file extensions for assets to be served to production from the assets subdirectory.  Example: jpeg,tif"
    end
    field :metadata_source_extensions, :enum do
      required(true)
      enum_method do
        :load_metadata_source_extensions
      end
      multiple do
        false
      end
      help "Required - comma-separated list of accepted file extensions for metadata source files to be served from the metadata subdirectory."
    end
    field :preservation_filename do
      required(true)
      help "Required - Filename for long-term preservation XML file"
    end
    list do
      field :directory do
        visible false
      end
      field :metadata_subdirectory do
        visible false
      end
      field :assets_subdirectory do
        visible false
      end
      field :file_extensions do
        visible false
      end
      field :metadata_source_extensions do
        visible false
      end
      field :preservation_filename do
        visible false
      end
      field :owner do
        visible true
      end
      field :title do
        visible true
      end
      field :directory_link do
        visible true
      end
      field :description do
        visible true
      end
    end

  end

end
