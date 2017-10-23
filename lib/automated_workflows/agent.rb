module AutomatedWorkflows
  class Agent

    attr_accessor :workflow
    attr_accessor :object_set
    attr_accessor :endpoint
    attr_accessor :options

    def initialize(workflow, object_set, endpoint, options = {})
      @workflow = workflow
      @object_set = object_set
      @endpoint = endpoint.chomp('/')
      @options = options
    end

    def instantiate_worker(step)
      klass_string = "#{self.workflow}::#{step}"
      klass = Object.const_get klass_string
      klass.new
    end

    def proceed
      self.object_set.each do |obj|
        repo = Repo.find_by(:unique_identifier => obj)
        steps_to_complete = determine_steps(repo.initial_stop, self.workflow)
        steps_to_complete = steps_to_complete - options[:steps_to_skip] if options[:steps_to_skip].present?
        metadata = self.instantiate_worker('Metadata') if (steps_to_complete & %w[fetch extract]).present?
        assets = self.instantiate_worker('Assets') if (steps_to_complete & %w[fetch file_check]).present?
        xml = self.instantiate_worker('XML') if (steps_to_complete & %w[xml]).present?
        ingest = self.instantiate_worker('Ingest') if (steps_to_complete & %w[ingest]).present?

        working_path = repo.version_control_agent.clone

        if steps_to_complete.include?('fetch')
          unless metadata.fetch(working_path, repo)
            repo.version_control_agent.delete_clone(working_path)
            repo.update_last_action(action_description[:fetch_metadata])
            next
          end
          unless assets.fetch(working_path, repo)
            repo.version_control_agent.delete_clone(working_path)
            repo.update_last_action(action_description[:fetch_assets])
            next
          end
        end

        if steps_to_complete.include?('extract')
          metadata.create_sources(working_path, repo)
          repo.update_last_action(action_description[:metadata_sources_updated])
          metadata.extract(working_path, repo)
          repo.update_last_action(action_description[:metadata_extracted])
        end

        if steps_to_complete.include?('file_check')
          assets.file_checks(working_path, repo)
          repo.update_last_action(action_description[:file_checks_run])
        end

        if steps_to_complete.include?('xml')
          xml.generate(working_path, repo)
          repo.update_last_action(action_description[:preservation_xml_generated])
        end

        if steps_to_complete.include?('ingest')
          ingest.ingest_and_index(working_path, repo)
          repo.update_last_action(action_description[:published_preview])
        end

        repo.version_control_agent.delete_clone(working_path)

      end

    end

    def determine_steps(repo_stop, workflow)
      return self.steps('fetch', AutomatedWorkflows.config['ingest_only']['initial_stop']) if workflow == AutomatedWorkflows::IngestOnly
      return self.steps('fetch', repo.initial_stop)
    end

    def steps(start = 'create', stop = 'create')
      steps = ['create','fetch','extract','file_check','xml','ingest']
      return steps[steps.index(start)..steps.index(stop)]
    end

    def action_description
      { :fetch_metadata => 'Automated: metadata fetched from endpoint',
        :fetch_assets => 'Automated: assets fetched from endpoint',
        :metadata_sources_updated => 'Automated: metadata source information updated',
        :metadata_extracted => 'Automated: metadata extraction from source(s) initialized',
        :metadata_mappings_generated => 'Automated: metadata mappings set',
        :file_checks_run => 'Automated: file checks and derivative generated',
        :preservation_xml_generated => 'Automated: preservation XML generated',
        :published_preview => 'Automated: object ingested' }
    end

    class << self

      def verify_sources(repo)
        repo.endpoint.each do |ep|
          source_problems(ep, ep.source, 'Source not found') unless AutomatedWorkflows::Actions::Binaries.source_exists?(ep.source)
        end
      end

      def source_problems(endpoint, source, problem)
        endpoint.problems[source] = problem
        endpoint.save!
      end
    end

  end
end
