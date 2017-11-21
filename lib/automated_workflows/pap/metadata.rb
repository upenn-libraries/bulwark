require 'rsync'
require 'rubyXL'

module AutomatedWorkflows
  module Pap
    class Metadata

      class << self
        def endpoint(repo)
          repo.endpoint.find_by(:content_type => 'metadata')
        end
      end

      def fetch(working_path, repo)
        metadata_endpoint = AutomatedWorkflows::Pap::Metadata.endpoint(repo)
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
        desc_source = "#{repo.metadata_subdirectory}/#{AutomatedWorkflows.config['pap']['csv']['metadata']['descriptive_filename']}"
        struct_source = "#{repo.metadata_subdirectory}/#{AutomatedWorkflows.config['pap']['csv']['metadata']['structural_filename']}"

        desc = MetadataSource.where(:metadata_builder => repo.metadata_builder, :path => desc_source).first_or_create
        desc.update_attributes( view_type: 'horizontal',
                                num_objects: 1,
                                x_start: 1,
                                y_start: 1,
                                x_stop: 1,
                                y_stop: 1,
                                root_element: 'record',
                                source_type: 'pap',
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
                                  source_type: 'pap_structural',
                                  z: 1 )

        desc.set_metadata_mappings(working_path)
        build_structural_spreadsheet(desc.original_mappings['bibid'], "#{working_path}/#{struct_source}")
        desc.children << struct
        desc.save!
      end

      def build_structural_spreadsheet(bib_id, save_path)
        workbook = RubyXL::Workbook.new
        workbook[0].add_cell(0,0,bib_id)
        FileUtils.rm(save_path) if File.exist?(save_path) || File.symlink?(save_path)
        workbook.write(save_path)
      end

      def extract(working_path, repo)
        repo.metadata_builder.get_mappings(working_path)
      end

    end
  end
end