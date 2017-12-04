require 'rsync'
require 'rubyXL'

module AutomatedWorkflows
  module Kaplan
    class Metadata

      class << self
        def endpoint(repo)
          repo.endpoint.find_by(:content_type => 'metadata')
        end
      end

      def fetch(working_path, repo)
        metadata_endpoint = AutomatedWorkflows::Kaplan::Metadata.endpoint(repo)
        source =  metadata_endpoint.source
        destination = "#{working_path}/#{metadata_endpoint.destination}"
        result = AutomatedWorkflows::Actions::Binaries.fetch(source, destination, repo.metadata_source_extensions)
        if result
          repo.version_control_agent.add(working_path)
          repo.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.automated.added_metadata'), working_path)
          repo.version_control_agent.push(working_path)
        else
          AutomatedWorkflows::Agent.source_problems(metadata_endpoint, source, 'Source not found')
        end
        result
      end

      def create_sources(working_path, repo)

        desc_source = "#{repo.metadata_subdirectory}/#{AutomatedWorkflows.config['kaplan']['csv']['metadata']['descriptive_filename']}"
        struct_source = "#{repo.metadata_subdirectory}/#{AutomatedWorkflows.config['kaplan']['csv']['metadata']['structural_filename']}"

        desc = MetadataSource.where(:metadata_builder => repo.metadata_builder, :path => desc_source).first_or_create
        desc.update_attributes( view_type: 'horizontal',
                                num_objects: 1,
                                x_start: 1,
                                y_start: 2,
                                x_stop: 34,
                                y_stop: 2,
                                root_element: 'record',
                                source_type: 'kaplan',
                                z: 1 )

        struct = MetadataSource.where(:metadata_builder => repo.metadata_builder, :path => struct_source).first_or_create
        struct.update_attributes( view_type: 'horizontal',
                                  num_objects: 1,
                                  x_start: 1,
                                  y_start: 1,
                                  x_stop: 1,
                                  y_stop: 1,
                                  root_element: 'pages',
                                  parent_element: 'page',
                                  source_type: 'kaplan_structural',
                                  file_field: 'file_name',
                                  z: 1 )
        desc.children << struct
        desc.set_metadata_mappings(working_path)
        desc.save!
      end

      def extract(working_path, repo)
        repo.metadata_builder.get_mappings(working_path)
      end

    end
  end
end