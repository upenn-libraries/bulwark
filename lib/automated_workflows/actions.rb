module AutomatedWorkflows
  module Actions
    extend self

    class Repos
      class << self
        def create(repo_name = nil, options = {})

          repo_type = options[:type] || 'default'
          owner = options[:owner] || nil
          description = options[:description] || nil
          last_external_update = options[:last_external_update] || nil
          initial_stop = options[:initial_stop] || nil
          endpoint_suffix = options[:endpoint_suffix] || ''
          assets_suffix = options[:assets_suffix] || ''

          human_readable_name = repo_name.present? ? repo_name : AutomatedWorkflows::Bulk::Constants::DEFAULTS[repo_type][:human_readable_name]

          metadata_subdirectory = AutomatedWorkflows::Actions::Constants::DEFAULTS[repo_type][:metadata_subdirectory]
          assets_subdirectory = AutomatedWorkflows::Actions::Constants::DEFAULTS[repo_type][:assets_subdirectory]
          file_extensions = AutomatedWorkflows::Actions::Constants::DEFAULTS[repo_type][:file_extensions]
          metadata_source_extensions = AutomatedWorkflows::Actions::Constants::DEFAULTS[repo_type][:metadata_source_extensions]
          preservation_filename = AutomatedWorkflows::Actions::Constants::DEFAULTS[repo_type][:preservation_filename]

          Repo.find_or_create_by(:human_readable_name => human_readable_name) do |repo|
            repo.owner = owner
            repo.description = description
            repo.metadata_subdirectory = metadata_subdirectory
            repo.assets_subdirectory = assets_subdirectory
            repo.file_extensions = file_extensions
            repo.metadata_source_extensions = metadata_source_extensions
            repo.preservation_filename = preservation_filename
            repo.last_external_update = last_external_update
            repo.endpoint_suffix = endpoint_suffix
            repo.assets_suffix = assets_suffix
            repo.initial_stop = initial_stop
          end
        end
      end
    end

    class Binaries
      class << self
        def fetch(source, destination, extensions)
          formatted_extensions = extensions.length == 1 ? "*.#{extensions.first}" : "*.{#{extensions.join(',')}}"
          fetch_path = "#{source}/#{formatted_extensions}".gsub('//','/')
          result = Rsync.run(fetch_path, destination)
          result
        end
      end

    end
  end
end
