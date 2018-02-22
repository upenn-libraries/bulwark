module AutomatedWorkflows
  module Kaplan
    class XML

      def generate(working_path, repo)
        repo.metadata_builder.metadata_source.first.generate_all_xml(working_path)
        repo.metadata_builder.read_and_store_xml(working_path)
      end

    end
  end
end