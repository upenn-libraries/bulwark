module AutomatedWorkflows
  class Agent

    attr_accessor :workflow
    attr_accessor :object_set
    attr_accessor :endpoint

    def initialize(workflow, object_set, endpoint)
      @workflow = workflow
      @object_set = object_set
      @endpoint = endpoint.chomp('/')

    end

    def instantiate_worker(step)
      klass_string = "#{self.workflow}::#{step}"
      klass = Object.const_get klass_string
      klass.new
    end

    def proceed
      self.object_set.each do |obj|
        repo = Repo.find_by(:human_readable_name => obj)
        steps_to_complete = self.steps('fetch', repo.initial_stop)
        metadata = self.instantiate_worker('Metadata') if steps_to_complete.include?('fetch' || 'extract')
        assets = self.instantiate_worker('Assets') if steps_to_complete.include?('fetch' || 'file_check' || 'ingest')
        xml = self.instantiate_worker('XML') if steps_to_complete.include?('xml')
        ingest = self.instantiate_worker('Ingest') if steps_to_complete.include?('ingest')

        working_path = repo.version_control_agent.clone
        if steps_to_complete.include?('fetch')
          metadata.fetch(working_path, self.endpoint, repo)
          assets.fetch(working_path, self.endpoint, repo)
        end

        if steps_to_complete.include?('extract')
          metadata.create_sources(working_path, repo)
          metadata.extract(working_path, repo)
        end

        if steps_to_complete.include?('file_check')
          assets.file_checks(working_path, repo)
        end

        if steps_to_complete.include?('xml')
          xml.generate(working_path, repo)
        end

        if steps_to_complete.include?('ingest')
          ingest.ingest_and_index(working_path, repo)
        end

        repo.version_control_agent.delete_clone

      end

    end

    def steps(start = 'create', stop = 'create')
      steps = ['create','fetch','extract','file_check','xml','ingest']
      return steps[steps.index(start)..steps.index(stop)]
    end

  end
end
