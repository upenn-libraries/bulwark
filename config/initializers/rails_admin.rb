require Rails.root.join('lib', 'rails_admin', 'git_actions.rb')
require Rails.root.join('lib', 'rails_admin', 'create_remote.rb')
require Rails.root.join('lib', 'rails_admin', 'clone_from_production.rb')
require Rails.root.join('lib', 'rails_admin', 'sign_off_production.rb')
require Rails.root.join('lib', 'rails_admin', 'ingest.rb')
require Rails.root.join('lib', 'rails_admin', 'generate_metadata.rb')
require Rails.root.join('lib', 'rails_admin', 'files_check.rb')
require Rails.root.join('lib', 'rails_admin', 'preview_xml.rb')
require Rails.root.join('lib', 'rails_admin', 'preserve.rb')
require Rails.root.join('lib', 'rails_admin', 'repo_new.rb')

RailsAdmin.config do |config|
  config.main_app_name = ['Review', 'Admin Dashboard']

  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  config.navigation_static_links = {
    'Front End' => '/'
  }

  config.included_models = ['Repo']

  config.actions do
    dashboard                     # mandatory
    index
    repo_new do
      only ['Repo']
    end
    git_actions do
      only ['Repo']
    end
    preserve do
      only ['Repo']
    end
    generate_metadata
    files_check
    preview_xml
    create_remote do
      only ['Repo']
    end
    ingest do
      only ['Repo']
    end
  end

  config.model Repo do
    field :human_readable_name do
      label I18n.t('colenda.rails_admin.new_repo.labels.human_readable_name')
      required(true)
    end
    field :directory_link do
      visible false
      label I18n.t('colenda.rails_admin.new_repo.labels.directory')
      pretty_value do
        %{#{value}}.html_safe
      end
    end
    field :description do
      required(false)
    end
    field :metadata_subdirectory do
      required(true)
      help I18n.t('colenda.rails_admin.new_repo.metadata_subdirectory.help')
    end
    field :assets_subdirectory do
      required(true)
      help I18n.t('colenda.rails_admin.new_repo.assets_subdirectory.help')
    end
    field :file_extensions, :enum do
      required(true)
      enum_method do
        :load_file_extensions
      end
      multiple do
        true
      end
      help I18n.t('colenda.rails_admin.new_repo.file_extensions.help')
    end
    field :metadata_source_extensions, :enum do
      required(true)
      enum_method do
        :load_metadata_source_extensions
      end
      multiple do
        false
      end
      help I18n.t('colenda.rails_admin.new_repo.metadata_source_extensions.help')
    end
    field :preservation_filename do
      required(true)
      help I18n.t('colenda.rails_admin.new_repo.preservation_filename.help')
    end
    list do
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
      field :human_readable_name do
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
