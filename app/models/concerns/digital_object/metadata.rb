# frozen_string_literal: true
module DigitalObject
  module Metadata
    extend ActiveSupport::Concern

    DESCRIPTIVE_METADATA_FILENAME = 'descriptive_metadata.csv'
    STRUCTURAL_METADATA_FILENAME = 'structural_metadata.csv'
    METS_FILENAME = 'mets.xml'

    def merge_descriptive_metadata(metadata)
      if (metadata_source = metadata_builder.metadata_source.find_by(source_type: 'descriptive'))
        desc_metadata_file = metadata_source.path
        get_and_unlock(desc_metadata_file)

        # Read in current metadata
        metadata_csv = File.open(File.join(clone_location, desc_metadata_file)).read
        current_desc_metadata = Bulwark::StructuredCSV.parse(metadata_csv).first

        # Merge metadata and generate new CSV
        new_metadata = current_desc_metadata.merge(metadata)
        csv_data = Bulwark::StructuredCSV.generate([new_metadata])

        # Save CSV to file
        File.write(File.join(clone_location, desc_metadata_file), csv_data)
      else
        # If metadata is not already present, create new metadata file
        csv_data = Bulwark::StructuredCSV.generate([metadata])
        desc_metadata_file = File.join(clone_location, metadata_subdirectory, DESCRIPTIVE_METADATA_FILENAME)
        File.write(desc_metadata_file, csv_data)
      end

      # add, commit, push descriptive  metadata
      version_control_agent.add({ content: desc_metadata_file }, clone_location)
      version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.automated.added_metadata'), clone_location)
      version_control_agent.push({ content: desc_metadata_file }, clone_location)

      # Create or update metadata source for descriptive metadata
      source = metadata_builder.metadata_source.find_or_create_by(source_type: 'descriptive') do |descriptive_source|
        descriptive_source.path = File.join(metadata_subdirectory, DESCRIPTIVE_METADATA_FILENAME)
      end

      # Extract
      source.set_metadata_mappings(clone_location)
      source.save!
    end

    # Update metadata retrieved from catalog.
    def update_catalog_metadata
      source = metadata_builder.metadata_source.find_by(source_type: 'descriptive')
      raise 'Descriptive metadata source not available' unless source

      bibnumber = source.original_mappings['bibnumber']&.first
      raise 'Descriptive metadata does not contain bibnumber' if bibnumber.blank?

      source.set_metadata_mappings(clone_location)
      source.save!
    end

    def add_structural_metadata(metadata)
      if (metadata_source = metadata_builder.metadata_source.find_by(source_type: 'structural'))
        struct_metadata_file = metadata_source.path
        get_and_unlock(struct_metadata_file)

        File.write(File.join(clone_location, struct_metadata_file), metadata)
      else
        File.write(File.join(clone_location, metadata_subdirectory, STRUCTURAL_METADATA_FILENAME), metadata)
      end

      version_control_agent.add({ content: struct_metadata_file }, clone_location)
      version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.automated.added_metadata'), clone_location)
      version_control_agent.push({ content: struct_metadata_file }, clone_location)

      # Create or update metadata source for structural metadata
      source = metadata_builder.metadata_source.find_or_create_by(source_type: 'structural') do |structural_source|
        structural_source.path = File.join(metadata_subdirectory, STRUCTURAL_METADATA_FILENAME)
      end

      # Extract Metadata
      source.set_metadata_mappings(clone_location)
      source.save!
    end

    def add_preservation_and_mets_xml
      # Create and add preservation.xml to repository
      preservation_filepath = File.join(metadata_subdirectory, preservation_filename)
      mets_filepath = File.join(metadata_subdirectory, METS_FILENAME)

      # If preservation and mets xml files are already present, retrieve and unlock them.
      [preservation_filepath, mets_filepath].each do |relative_path|
        if ExtendedGit.open(clone_location).annex.whereis.includes_file?(relative_path)
          get_and_unlock(relative_path)
        end
      end

      # Write new xml to files.
      File.write(File.join(clone_location, preservation_filepath), metadata_builder.preservation_xml)
      File.write(File.join(clone_location, mets_filepath), metadata_builder.mets_xml)

      # add, commit, push
      version_control_agent.add({ content: metadata_subdirectory }, clone_location)
      version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.write_preservation_xml'), clone_location)
      version_control_agent.push({ content: metadata_subdirectory }, clone_location)

      # Save link to xml files in metadata_builder
      metadata_builder.update(
        generated_metadata_files: {
          preservation_filepath.to_s => File.join(names.bucket, version_control_agent.look_up_key(preservation_filepath, clone_location)).to_s,
          mets_filepath.to_s => File.join(names.bucket, version_control_agent.look_up_key(mets_filepath, clone_location)).to_s
        }
      )
    end
  end
end
