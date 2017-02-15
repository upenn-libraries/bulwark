require 'active_record'
require 'activerecord-import'

module AutomatedWorkflows
  module Bulk
    class CreateManageRepos
      class << self

        def create_repo(repo_name = nil, options = {})

          repo_type = options[:type] || 'default'
          owner = options[:owner] || nil
          description = options[:description] || nil
          last_external_update = options[:last_external_update] || nil


          human_readable_name = repo_name.present? ? repo_name : AutomatedWorkflows::Bulk::Constants::DEFAULTS[repo_type][:human_readable_name]

          metadata_subdirectory = AutomatedWorkflows::Bulk::Constants::DEFAULTS[repo_type][:metadata_subdirectory]
          assets_subdirectory = AutomatedWorkflows::Bulk::Constants::DEFAULTS[repo_type][:assets_subdirectory]
          file_extensions = AutomatedWorkflows::Bulk::Constants::DEFAULTS[repo_type][:file_extensions]
          metadata_source_extensions = AutomatedWorkflows::Bulk::Constants::DEFAULTS[repo_type][:metadata_source_extensions]
          preservation_filename = AutomatedWorkflows::Bulk::Constants::DEFAULTS[repo_type][:preservation_filename]

          Repo.create(:human_readable_name => human_readable_name,
                      :owner => owner,
                      :description => description,
                      :metadata_subdirectory => metadata_subdirectory,
                      :assets_subdirectory => assets_subdirectory,
                      :file_extensions => file_extensions,
                      :metadata_source_extensions => metadata_source_extensions,
                      :preservation_filename => preservation_filename,
                      :last_external_update => last_external_update)
        end
      end
    end
  end
end