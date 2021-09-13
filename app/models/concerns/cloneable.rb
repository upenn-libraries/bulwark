# frozen_string_literal: true
module Cloneable
  extend ActiveSupport::Concern

  DESCRIPTIVE_METADATA_FILENAME = 'descriptive_metadata.csv'
  STRUCTURAL_METADATA_FILENAME = 'structural_metadata.csv'
  METS_FILENAME = 'mets.xml'
  JHOVE_OUTPUT_FILENAME = 'jhove_output.xml'

  def clone_location
    @clone_location ||= version_control_agent.clone
  end

  # Returns true if there is a cloned repo
  def cloned?
    @clone_location.present?
  end

  # Retrieving assets from the given path, adding them
  # to the git repo and characterizing assets.
  def add_assets(path)
    copy_assets(path)
    characterize_assets
    create_or_update_assets
  end

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

  # Extracts data from metadata files and saves it in database.
  def extract_from_metadata_sources
    metadata_builder.get_mappings(clone_location)
  end

  def generate_derivatives
    get_and_unlock(derivatives_subdirectory)

    # Create 'thumbnails' and 'access' directories if they arent present already.
    access_dir_path = File.join(clone_location, derivatives_subdirectory, 'access')
    thumbnail_dir_path = File.join(clone_location, derivatives_subdirectory, 'thumbnails')

    [access_dir_path, thumbnail_dir_path].each do |dir|
      FileUtils.mkdir(dir) unless File.exist?(dir)
    end

    # Create derivatives for jpeg and tiff files.
    assets.each do |asset|
      next unless asset.mime_type == 'image/jpeg' || asset.mime_type == 'image/tiff'
      relative_file_path = File.join(assets_subdirectory, asset.filename)
      get_and_unlock(relative_file_path)

      file_path = File.join(clone_location, relative_file_path)

      access_filepath = Bulwark::Derivatives::Image.access_copy(file_path, access_dir_path)
      access_relative_path = Pathname.new(access_filepath).relative_path_from(Pathname.new(clone_location)).to_s
      version_control_agent.add({ content: access_relative_path, include_dotfiles: true }, clone_location)
      asset.access_file_location = version_control_agent.look_up_key(access_relative_path, clone_location)

      thumbnail_filepath = Bulwark::Derivatives::Image.thumbnail(file_path, thumbnail_dir_path)
      thumbnail_relative_path = Pathname.new(thumbnail_filepath).relative_path_from(Pathname.new(clone_location)).to_s
      version_control_agent.add({ content: thumbnail_relative_path, include_dotfiles: true }, clone_location)
      asset.thumbnail_file_location = version_control_agent.look_up_key(thumbnail_relative_path, clone_location)

      asset.save!

      version_control_agent.lock(relative_file_path, clone_location)
      version_control_agent.drop({ content: relative_file_path }, clone_location)
    end

    metadata_builder.update!(last_file_checks: DateTime.current)

    version_control_agent.lock(derivatives_subdirectory, clone_location)
    version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.generated_all_derivatives', object_id: names.fedora), clone_location)
    version_control_agent.push(clone_location)
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

  # Dropping annex'ed content and removing clone.
  #
  # TODO: Using `FileUtils.rm_rf` does not raise StandardErrors. We might want to
  # at least log those errors, if we don't want them raised.
  #
  # TODO: We might want to `git annex uninit` before we delete a cloned repository
  # because that way, the repository is removed from the list of repositories
  # when doing a `git annex info` and the `.git/annex` directory
  # and its contents are completely deleted.
  def delete_clone
    # Forcefully dropping content because if an error occurred we might not
    # be able to drop all the files without forcing.
    ExtendedGit.open(clone_location).annex.drop(all: true, force: true)

    parent_dir = Pathname.new(clone_location).parent
    FileUtils.rm_rf(parent_dir, secure: true) if File.directory?(parent_dir)

    @clone_location = nil
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
      asset.mime_type = jhove_output.mime_type_for(filename)
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

    # Helper methods for frequently used git-annex tasks
    # Retrieving file and unlocking it. Usually needed before trying to access git-annex'ed files.
    # Should provide a relative path from the root of the cloned repository.
    def get_and_unlock(relative_path)
      version_control_agent.get({ location: relative_path }, clone_location)
      version_control_agent.unlock({ content: relative_path }, clone_location)
    end
end
