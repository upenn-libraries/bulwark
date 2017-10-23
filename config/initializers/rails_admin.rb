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
require Rails.root.join('lib', 'rails_admin', 'batch_new.rb')
require Rails.root.join('lib', 'rails_admin', 'in_queue.rb')

RailsAdmin::Config::Actions.register(RailsAdmin::Config::Actions::InQueue)


RailsAdmin.config do |config|
  config.main_app_name = ['Review', 'Admin Dashboard']

  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  config.navigation_static_links = {
    'Front End' => '/'
  }

  config.included_models = ['Repo', 'Batch']

  config.actions do
    dashboard                     # mandatory
    index
    in_queue
    repo_new do
      only ['Repo']
    end
    batch_new do
      only ['Batch']
    end
    git_actions do
      only ['Repo']
    end
    delete do
      only ['Batch']
    end
    preserve do
      only ['Repo']
    end
    generate_metadata do
      only ['Repo']
    end
    files_check do
      only ['Repo']
    end
    preview_xml do
      only ['Repo']
    end
    create_remote do
      only ['Repo']
    end
    ingest do
      only ['Repo']
    end
  end

  config.model Batch do
    field :queue_list, :enum do
      label 'Queue List'
      enum_method do
        :load_all_queueable
      end
      multiple do
        true
      end
      required(true)
    end
    field :email do
      required(true)
    end
    list do
      field :queue_list do
        visible true
        searchable true
      end
      field :email do
        visible true
        searchable true
      end
      field :status do
        visible true
        searchable true
      end
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
        searchable true
      end
      field :human_readable_name do
        visible true
        searchable true
      end
      field :directory_link do
        visible true
      end
      field :description do
        visible true
      end
      field :last_action_performed do
        visible true
        searchable true
        pretty_value do
          %{#{value[:description]}}.html_safe
        end
      end
    end

  end

end
