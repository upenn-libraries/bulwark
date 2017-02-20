module AutomatedWorkflows
  module OPenn
    class Assets

      def fetch(working_path, endpoint, repo)
        source = [endpoint, repo.endpoint_suffix, repo.assets_suffix].reject(&:blank?).join('/')
        destination = "#{working_path}/#{repo.assets_subdirectory}"
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