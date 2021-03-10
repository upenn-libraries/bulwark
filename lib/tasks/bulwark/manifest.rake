# frozen_string_literal: true
namespace :bulwark do
  namespace :manifest do
    task load: :environment do
      # Create manifest file.
      manifest = <<~MANIFEST
        share,path,unique_identifier,timestamp,directive_name,status
        test,object_one,,,"Object One",
      MANIFEST

      manifest_filepath = Rails.root.join('tmp', 'manifest.csv').to_s
      File.open(manifest_filepath, 'w') { |f| f.write(manifest) }

      # Create object through Kaplan manifest load.
      repos = AutomatedWorkflows::Kaplan::Csv.generate_repos(manifest_filepath)
      AutomatedWorkflows::Agent.new(
        AutomatedWorkflows::Kaplan,
        repos,
        AutomatedWorkflows::Kaplan::Csv.config.endpoint('test'),
        steps_to_skip: ['ingest']
      ).proceed

      # Ingest item to Fedora and Solr.
      AutomatedWorkflows::Agent.new(
        AutomatedWorkflows::IngestOnly,
        repos,
        '',
        steps_to_skip: AutomatedWorkflows.config[:ingest_only][:steps_to_skip]
      ).proceed

      # Delete manifest file
      File.delete(manifest_filepath)
    end
  end
end
