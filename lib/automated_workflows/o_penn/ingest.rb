module AutomatedWorkflows
  module OPenn
    class Ingest

      def ingest_and_index(working_path, repo)
        preservation = "#{repo.metadata_subdirectory}/#{repo.preservation_filename}"
        params = { preservation => preservation }
        repo.metadata_builder.ingest(working_path,params)
        Utils::Process.refresh_assets(repo)
      end

    end
  end
end