require 'rsync'
require 'rubyXL'

module AutomatedWorkflows
  module OPenn
    class Metadata

      def fetch(working_path, endpoint, repo)
        source = [endpoint, repo.endpoint_suffix, repo.metadata_suffix].join('/')
        destination = "#{working_path}/#{repo.metadata_subdirectory}"
        result = AutomatedWorkflows::Actions::Binaries.fetch(source, destination, repo.metadata_source_extensions)
        repo.version_control_agent.add
        repo.version_control_agent.commit("Added metadata")
        repo.version_control_agent.push
        result
      end

      def create_sources(working_path, repo)
        desc_source = "#{repo.metadata_subdirectory}/MM_metadata.xlsx"
        struct_source = "#{repo.metadata_subdirectory}/MM_struct_metadata.xlsx"

        desc = MetadataSource.create( metadata_builder: repo.metadata_builder,
                                      path: desc_source,
                                      view_type: 'horizontal',
                                      num_objects: 1,
                                      x_start: 1,
                                      y_start: 1,
                                      x_stop: 1,
                                      y_stop: 1,
                                      root_element: 'record',
                                      source_type: 'voyager',
                                      metadata_builder_id: repo.metadata_builder.id,
                                      z: 1 )

        struct = MetadataSource.create( metadata_builder: repo.metadata_builder,
                                        path: struct_source,
                                        view_type: 'horizontal',
                                        num_objects: 1,
                                        x_start: 1,
                                        y_start: 1,
                                        x_stop: 1,
                                        y_stop: 1,
                                        root_element: 'pages',
                                        parent_element: 'page',
                                        source_type: 'structural_bibid',
                                        z: 1 )

        desc.set_metadata_mappings(working_path)
        build_structural_spreadsheet(desc.original_mappings['bibid'], "#{working_path}/#{struct_source}")
        desc.children << struct
        desc.save!
      end

      def build_structural_spreadsheet(bib_id, save_path)
        workbook = RubyXL::Workbook.new
        workbook[0].add_cell(0,0,bib_id)
        workbook.write(save_path)
      end

      def extract(working_path, repo)
        repo.metadata_builder.get_mappings(working_path)
      end

    end
  end
end