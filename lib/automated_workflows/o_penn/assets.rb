module AutomatedWorkflows
  module OPenn
    class Assets

      class << self
        def endpoint(repo)
          repo.endpoint.find_by(:content_type => 'assets')
        end
      end

      def fetch(working_path, repo)
        assets_endpoint = AutomatedWorkflows::OPenn::Assets.endpoint(repo)
        source =  assets_endpoint.source
        destination = "#{working_path}/#{assets_endpoint.destination}"
        result = AutomatedWorkflows::Actions::Binaries.fetch(source, destination, repo.file_extensions)
        repo.version_control_agent.add
        repo.version_control_agent.commit("Added assets")
        repo.version_control_agent.push
        result
      end

      def file_checks(working_path, repo)
        repo.metadata_builder.file_checks_previews(working_path)
        Utils::Process.refresh_assets(repo)
      end

    end
  end
end