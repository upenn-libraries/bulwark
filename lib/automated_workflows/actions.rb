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

          human_readable_name = repo_name.present? ? repo_name : AutomatedWorkflows::Bulk::Constants::DEFAULTS[repo_type][:human_readable_name]

          metadata_subdirectory = AutomatedWorkflows::Constants::DEFAULTS[repo_type][:metadata_subdirectory]
          assets_subdirectory = AutomatedWorkflows::Constants::DEFAULTS[repo_type][:assets_subdirectory]
          file_extensions = AutomatedWorkflows::Constants::DEFAULTS[repo_type][:file_extensions]
          metadata_source_extensions = AutomatedWorkflows::Constants::DEFAULTS[repo_type][:metadata_source_extensions]
          preservation_filename = AutomatedWorkflows::Constants::DEFAULTS[repo_type][:preservation_filename]

          repo = Repo.where(:human_readable_name => human_readable_name).first_or_create
          repo.update_attributes(
            owner: owner,
            description: description,
            metadata_subdirectory: metadata_subdirectory,
            assets_subdirectory: assets_subdirectory,
            file_extensions: file_extensions,
            metadata_source_extensions: metadata_source_extensions,
            preservation_filename: preservation_filename,
            last_external_update: last_external_update,
            initial_stop: initial_stop)
          repo
          end
        end
      end

    class Binaries
      class << self
        def fetch(source, destination, extensions)
          unless source_exists?(source)
            Rails.logger.warn "#{source} not found"
            return false
          end
          formatted_extensions = extensions.length == 1 ? "*.#{extensions.first}" : "*.{#{extensions.join(',')}}"
          fetch_path = "#{source}/#{formatted_extensions}".gsub('//','/')
          Rsync.run(fetch_path, destination) do |result|
            if result.success?
              result.changes.each do |change|
                Rails.logger.info "#{change.filename} (#{change.summary})"
              end
            else
              Rails.logger.warn result.error
            end
          end
          return true
        end

        def source_exists(source)
          File.exist?(source)
        end
        alias_method :source_exists?, :source_exists

      end
    end
  end
end
