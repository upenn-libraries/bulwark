module AutomatedWorkflows
  module Pap
    class Assets

      class << self
        def endpoint(repo)
          repo.endpoint.find_by(:content_type => 'assets')
        end
      end

      def fetch(working_path, repo)
        assets_endpoint = AutomatedWorkflows::Pap::Assets.endpoint(repo)
        source =  assets_endpoint.source
        destination = "#{working_path}/#{assets_endpoint.destination}"
        result = AutomatedWorkflows::Actions::Binaries.fetch(source, destination, repo.file_extensions)
        if result
          repo.version_control_agent.add(working_path)
          repo.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.automated.added_assets'), working_path)
          repo.version_control_agent.push(working_path)
        else
          AutomatedWorkflows::Agent.source_problems(assets_endpoint, source, 'Source not found')
        end
        result
      end

      def file_checks(working_path, repo)
        repo.metadata_builder.file_checks_previews(working_path)
        Utils::Process.refresh_assets(working_path, repo)
      end

    end
  end
end