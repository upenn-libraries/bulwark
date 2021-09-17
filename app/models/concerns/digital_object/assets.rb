# frozen_string_literal: true
require 'jhove_service'

module DigitalObject
  module Assets
    extend ActiveSupport::Concern

    DESCRIPTIVE_METADATA_FILENAME = 'descriptive_metadata.csv'
    STRUCTURAL_METADATA_FILENAME = 'structural_metadata.csv'
    METS_FILENAME = 'mets.xml'
    JHOVE_OUTPUT_FILENAME = 'jhove_output.xml'

    # Retrieving assets from the given path, adding them
    # to the git repo and characterizing assets.
    def add_assets(path)
      copy_assets(path)
      characterize_assets
      create_or_update_assets
    end

    # File characterization via jhove.
    def characterize_assets
      get_and_unlock(assets_subdirectory)

      # Retrieve the jhove output file if present in order to update it.
      jhove_output_filepath = File.join(metadata_subdirectory, JHOVE_OUTPUT_FILENAME)
      if ExtendedGit.open(clone_location).annex.whereis.includes_file?(jhove_output_filepath)
        version_control_agent.get({ location: jhove_output_filepath }, clone_location)
        version_control_agent.unlock({ content: jhove_output_filepath }, clone_location)
      end

      # Runs jhove on `data/assets` stores output in `data/metadata/jhove_output.xml`.
      # Because we unlock the files before running jhove the filename will be
      # used in the jhove output. Otherwise the file's location in git is used.
      jhove_output = JhoveService.new(File.join(clone_location, metadata_subdirectory))
                                 .run_jhove(File.join(clone_location, assets_subdirectory))

      version_control_agent.lock(assets_subdirectory, clone_location)

      version_control_agent.add({ content: File.join(metadata_subdirectory, File.basename(jhove_output)) }, clone_location)
      version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.generated_preservation_metadata', object_id: names.fedora), clone_location)
      version_control_agent.push({ content: File.join(metadata_subdirectory, File.basename(jhove_output)) }, clone_location)
    end

    # Create or update asset records.
    def create_or_update_assets
      # All files in assets folder
      glob_path = File.join(clone_location, assets_subdirectory, "*.{#{file_extensions.join(',')}}")
      assets_paths = Dir.glob(glob_path) # full paths

      # Get jhove output in order to get the mime type and size for each asset.
      version_control_agent.get({ location: File.join(metadata_subdirectory, JHOVE_OUTPUT_FILENAME) }, clone_location)
      jhove_output = Bulwark::JhoveOutput.new(File.join(clone_location, metadata_subdirectory, JHOVE_OUTPUT_FILENAME))

      # Updating or creating asset record for each asset file
      assets_paths.each do |asset_path|
        filename = File.basename(asset_path)
        asset = assets.find_or_initialize_by(filename: filename)
        asset.original_file_location = version_control_agent.look_up_key(File.join(assets_subdirectory, filename), clone_location)
        asset.size = jhove_output.size_for(filename) # In bytes
        asset.mime_type = MIME::Type.simplified(jhove_output.mime_type_for(filename))
        asset.save!
      end

      # Removing references to files that have been removed.
      asset_filenames = assets_paths.map { |a| File.basename(a) }
      assets.each do |asset|
        asset.destroy unless asset_filenames.include?(asset.filename)
      end
    end

    private

      def copy_assets(path)
        get_and_unlock(assets_subdirectory)
        assets_directory = File.join(clone_location, assets_subdirectory)

        Bulwark::FileUtilities.copy_files(path, assets_directory, file_extensions)

        version_control_agent.add({}, clone_location)
        version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.automated.added_assets'), clone_location)
        version_control_agent.push({}, clone_location)
      end
    end
end
