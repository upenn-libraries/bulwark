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
  config.main_app_name = ["Intermediary", "Admin Interface"]

  config.included_models = ["Repo"]

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    edit
    delete
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
  end

  config.model Repo do
    field :title do
      required(true)
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
    field :file_extensions do
      required(true)
      help "Required - comma-separated list of accepted file extensions for assets to be served to production from the assets subdirectory.  Example: jpeg,tif"
    end
    field :preservation_filename do
      required(true)
      help "Required - Filename for long-term preservation XML file"
    end
  end

end
