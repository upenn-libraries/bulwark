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

          human_readable_name = repo_name.present? ? repo_name : AutomatedWorkflows::Constants::DEFAULTS[repo_type][:human_readable_name]

          metadata_subdirectory = AutomatedWorkflows::Constants::DEFAULTS[repo_type][:metadata_subdirectory]
          assets_subdirectory = AutomatedWorkflows::Constants::DEFAULTS[repo_type][:assets_subdirectory]
          file_extensions = AutomatedWorkflows::Constants::DEFAULTS[repo_type][:file_extensions]
          metadata_source_extensions = AutomatedWorkflows::Constants::DEFAULTS[repo_type][:metadata_source_extensions]
          preservation_filename = AutomatedWorkflows::Constants::DEFAULTS[repo_type][:preservation_filename]

          repo = Repo.where(:human_readable_name => human_readable_name).first_or_create do |param|
            param.metadata_subdirectory = metadata_subdirectory
            param.assets_subdirectory = assets_subdirectory
            param.file_extensions = file_extensions
            param.metadata_source_extensions = metadata_source_extensions
            param.preservation_filename = preservation_filename
            param.unique_identifier = options[:unique_identifier] if options[:unique_identifier].present?
          end

          repo.update_attributes(
            owner: owner,
            description: description,
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
          formatted_extensions = ''
          other_flags = '--exclude="*"'
          extensions.each{|ext| formatted_extensions << " --include=*.#{ext}"}
          fetch_path = "#{source}".gsub('//','/')
          Rsync.run(fetch_path, destination, "-av #{formatted_extensions} #{other_flags}") do |result|
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
