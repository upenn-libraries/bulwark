# frozen_string_literal: true
require 'jhove_service'

module Bulwark
  class Import
    CREATE = 'create'
    UPDATE = 'update'
    IMPORT_ACTIONS = [CREATE, UPDATE].freeze
    DESCRIPTIVE_METADATA_FILENAME = 'descriptive_metadata.csv'
    STRUCTURAL_METADATA_FILENAME = 'structural_metadata.csv'
    METS_FILENAME = 'mets.xml'
    JHOVE_OUTPUT_FILENAME = 'jhove_output.xml'

    attr_reader :unique_identifier, :action, :directive, :created_by, :assets,
                :descriptive_metadata, :structural_metadata,
                :repo, :clone_location, :errors

    # Initializes object to import digital objects.
    #
    # @param [Hash] arguments passed in to create/update digital objects
    # @options opts [String] :action
    # @options opts [User] :created_by
    # @options opts [String] :directive
    # @options opts [String] :unique_identifier
    # @options opts [Hash] :assets
    # @options opts [Hash] :metadata  # gets mapped to descriptive_metadata
    # @options opts [Hash] :structural  # gets mapped to structural_metadata
    def initialize(args)
      args = args.deep_symbolize_keys

      @action = args[:action]
      @unique_identifier = args[:unique_identifier]
      @directive = args[:directive]
      @created_by = args[:created_by]
      @descriptive_metadata = args.fetch(:metadata, {})
      @structural_metadata = args.fetch(:structural, {})
      @assets = args.fetch(:assets, {})
      @errors = []
    end

    # Validates that digital object can be created or updated with all the information
    # given. These checks are meant to be lightweight checks that can be done
    # before pulling down the entire repository. Returns false if there is
    # missing or incorrect information. Errors are stored in an instance variable.
    #
    # @return [True] if no errors were generated
    # @ return [False] if errors were generated
    def validate
      @errors << "\"#{action}\" is not a valid import action" unless IMPORT_ACTIONS.include?(action)

      if action == CREATE
        @errors << "\"directive\" must be provided to create an object" unless directive
        @errors << "structural must be provided to create an object" unless structural_metadata && (structural_metadata[:filenames] || (structural_metadata[:drive] && structural_metadata[:path]))
        @errors << "\"assets.path\" and \"assets.drive\" must be provided to create an object" if assets && (!assets[:drive] || !assets[:path])
        @errors << "metadata must be provided to create an object" if descriptive_metadata.blank?
        if unique_identifier
          @errors << "\"#{unique_identifier}\" already belongs to an object. Cannot create new object with given unique identifier." if Repo.find_by(unique_identifier: unique_identifier)
          @errors << "\"#{unique_identifier}\" is not minted" if unique_identifier && !Utilities.ark_exists?(unique_identifier)
        end
      end

      if action == UPDATE
        @errors << "\"unique_identifier\" must be provided when updating an object" unless unique_identifier
        @errors << "\"unique_identifier\" does not belong to an object. Cannot update object." if unique_identifier && !Repo.find_by(unique_identifier: unique_identifier)
      end

      if assets
        @errors << "asset drive invalid" if assets[:drive] && !MountedDrives.valid?(assets[:drive])
        @errors << "asset path invalid" if assets[:drive] && assets[:path] && !MountedDrives.valid_path?(assets[:drive], assets[:path])
      end

      if structural_metadata
        @errors << "cannot provide structural metadata two different ways" if (structural_metadata[:drive] || structural_metadata[:path]) && structural_metadata[:filenames]
        @errors << "structural drive invalid" if structural_metadata[:drive] && !MountedDrives.valid?(structural_metadata[:drive])
        @errors << "structural path invalid" if structural_metadata[:drive] && structural_metadata[:path] && !MountedDrives.valid_path?(structural_metadata[:drive], structural_metadata[:path])
      end

      @errors << "created_by must always be provided" unless created_by
      errors.empty?
    end

    def process
      # Validate before processing data
      return Result.new(status: DigitalObjectImport::FAILED, errors: errors) unless validate

      @repo = case action.downcase
              when CREATE
                create_digital_object
              when UPDATE
                Repo.find_by(unique_identifier: unique_identifier)
              end

      update_digital_object(repo)

      clone_location = repo.version_control_agent.clone # Path to cloned location

      # Copy over assets and commit them to repository.
      copy_assets(clone_location)

      # File characterization via jhove.
      characterize_assets(clone_location)

      # Create or update asset records.
      create_or_update_assets(clone_location)

      # Add descriptive metadata
      unless descriptive_metadata.empty?
        # If metadata is already present merge metadata, otherwise create new
        # metadata file.
        if (metadata_source = repo.metadata_builder.metadata_source.find_by(source_type: 'descriptive'))
          desc_metadata_file = metadata_source.path
          repo.version_control_agent.get({ location: desc_metadata_file }, clone_location)
          repo.version_control_agent.unlock({ content: desc_metadata_file }, clone_location)

          # Read in current metadata
          metadata_csv = File.open(File.join(clone_location, desc_metadata_file)).read
          current_desc_metadata = Bulwark::StructuredCSV.parse(metadata_csv).first

          # Merge metadata and generate new CSV
          metadata = current_desc_metadata.merge(descriptive_metadata.deep_stringify_keys)
          csv_data = Bulwark::StructuredCSV.generate([metadata])

          # Save CSV to file
          File.write(File.join(clone_location, desc_metadata_file), csv_data)
        else
          # If metadata is not already present, create new metadata file
          csv_data = Bulwark::StructuredCSV.generate([descriptive_metadata])
          File.write(File.join(clone_location, repo.metadata_subdirectory, DESCRIPTIVE_METADATA_FILENAME), csv_data)
        end
      end

      # Add structural metadata. Replace structural metadata if its already present.
      # FIXME: This isn't a great solution because there is a potential for
      # data loss if more detailed structural metadata is already available.
      new_structural = nil
      if (ordered_filenames = structural_metadata[:filenames])
        # Generate structural metadata file based on contents in Bulk import csv given or path given.
        new_structural = CSV.generate do |csv|
          csv << ['filename', 'sequence']
          ordered_filenames.split('; ').each_with_index do |f, i|
            csv << [f, i + 1]
          end
        end
      elsif structural_metadata[:drive] && structural_metadata[:path]
        filepath = File.join(MountedDrives.path_to(structural_metadata[:drive]), structural_metadata[:path])
        raise 'structural metadata path must lead to a file.' unless File.file?(filepath)
        new_structural = File.read(filepath)
      end

      if new_structural
        if (metadata_source = repo.metadata_builder.metadata_source.find_by(source_type: 'structural'))
          struct_metadata_file = metadata_source.path
          repo.version_control_agent.get({ location: struct_metadata_file }, clone_location)
          repo.version_control_agent.unlock({ content: struct_metadata_file }, clone_location)

          File.write(File.join(clone_location, struct_metadata_file), new_structural)
        else
          File.write(File.join(clone_location, repo.metadata_subdirectory, STRUCTURAL_METADATA_FILENAME), new_structural)
        end
      end

      # add, commit, push descriptive and structural metadata
      repo.version_control_agent.add({}, clone_location)
      repo.version_control_agent.lock('.', clone_location)
      repo.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.automated.added_metadata'), clone_location)
      repo.version_control_agent.push({}, clone_location)

      # Create or update metadata source for descriptive and structural metadata
      repo.metadata_builder.metadata_source.find_or_create_by(source_type: 'descriptive') do |descriptive_source|
        descriptive_source.path = File.join(repo.metadata_subdirectory, DESCRIPTIVE_METADATA_FILENAME)
      end

      repo.metadata_builder.metadata_source.find_or_create_by(source_type: 'structural') do |structural_source|
        structural_source.path = File.join(repo.metadata_subdirectory, STRUCTURAL_METADATA_FILENAME)
      end

      # "Extract" metadata
      repo.metadata_builder.get_mappings(clone_location)

      # Derivative generation
      generate_derivatives(clone_location)

      # Create Thumbnail
      thumbnail = repo.structural_metadata.user_defined_mappings['sequence'].sort_by { |file| file['sequence'] }.first['filename']
      thumbnail_location = File.join(repo.names.bucket, repo.assets.find_by!(filename: thumbnail).thumbnail_file_location)
      repo.update!(
        thumbnail: thumbnail,
        thumbnail_location: thumbnail_location
      )

      # Generate xml: generate mets.xml and preservation.xml (can be moved to earlier in the process)
      add_preservation_and_mets_xml(clone_location)

      # TODO: Create Marmite IIIF Document?

      # TODO: ingest: index straight into Solr, skip Fedora.

      Result.new(status: DigitalObjectImport::SUCCESSFUL, unique_identifier: repo.unique_identifier)
    rescue => e
      Honeybadger.notify(e) # Sending full error to Honeybadger.
      Result.new(status: DigitalObjectImport::FAILED, errors: [e.message], unique_identifier: repo&.unique_identifier)
    end

    private

      def create_or_update_assets(clone_location)
        # All files in assets folder
        glob_path = File.join(clone_location, repo.assets_subdirectory, "*.{#{repo.file_extensions.join(",")}}")
        assets_paths = Dir.glob(glob_path) #full paths

        # Get jhove output in order to get the mime type and size for each asset.
        repo.version_control_agent.get({ location: File.join(repo.metadata_subdirectory, JHOVE_OUTPUT_FILENAME) }, clone_location)
        jhove_output = JhoveOutput.new(File.join(clone_location, repo.metadata_subdirectory, JHOVE_OUTPUT_FILENAME))

        # Updating or creating asset record for each asset file
        assets_paths.each do |asset_path|
          filename = File.basename(asset_path)
          repo.assets.find_or_create_by(filename: filename) do |asset|
            asset.original_file_location = repo.version_control_agent.look_up_key(File.join(repo.assets_subdirectory, filename), clone_location)
            asset.size = jhove_output.size_for(filename) # In bytes
            asset.mime_type = jhove_output.mime_type_for(filename)
          end
        end

        # Removing references to files that have been removed.
        asset_filenames = assets_paths.map { |a| File.basename(a) }
        repo.assets.each do |asset|
          asset.destroy unless asset_filenames.include?(asset.filename)
        end
      end

      def generate_derivatives(clone_location)
        repo.version_control_agent.get({ location: repo.assets_subdirectory }, clone_location)
        repo.version_control_agent.get({ location: repo.derivatives_subdirectory }, clone_location)
        repo.version_control_agent.unlock({ content: repo.derivatives_subdirectory }, clone_location)

        # Create 'thumbnails' and 'access' directories if they arent present already.
        access_dir_path = File.join(clone_location, repo.derivatives_subdirectory, 'access')
        thumbnail_dir_path = File.join(clone_location, repo.derivatives_subdirectory, 'thumbnails')

        [access_dir_path, thumbnail_dir_path].each do |dir|
          FileUtils.mkdir(dir) unless File.exist?(dir)
        end

        # Create derivatives for every asset.
        repo.assets.each do |asset|
          next unless asset.mime_type == 'image/jpeg' || asset.mime_type == 'image/tiff'
          file_path = File.join(clone_location, repo.assets_subdirectory, asset.filename)
          repo.version_control_agent.unlock({ content: file_path }, clone_location)

          access_filepath = Derivatives::Image.access_copy(file_path, access_dir_path)
          repo.version_control_agent.add({content: access_filepath, include_dotfiles: true}, clone_location)
          asset.access_file_location = repo.version_control_agent.look_up_key(access_filepath, clone_location)

          thumbnail_filepath = Derivatives::Image.thumbnail(file_path, thumbnail_dir_path)
          repo.version_control_agent.add({content: thumbnail_filepath, include_dotfiles: true}, clone_location)
          asset.thumbnail_file_location = repo.version_control_agent.look_up_key(thumbnail_filepath, clone_location)

          asset.save!

          repo.version_control_agent.add({content: file_path}, clone_location)
          repo.version_control_agent.lock(file_path, clone_location)
        end

        repo.metadata_builder.update!(last_file_checks: DateTime.now)

        repo.version_control_agent.add({ content: repo.derivatives_subdirectory, include_dotfiles: true }, clone_location)
        repo.version_control_agent.lock(repo.derivatives_subdirectory, clone_location)
        repo.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.generated_all_derivatives', object_id: repo.names.fedora), clone_location)
        repo.version_control_agent.push(clone_location)
      end

      def characterize_assets(clone_location)
        repo.version_control_agent.get({ location: repo.assets_subdirectory }, clone_location)
        repo.version_control_agent.unlock({ content: repo.assets_subdirectory}, clone_location)

        # Retrieve the jhove output file if present in order to update it.
        jhove_output_filepath = File.join(repo.metadata_subdirectory, JHOVE_OUTPUT_FILENAME)
        if ExtendedGit.open(clone_location).annex.whereis.includes_file?(jhove_output_filepath)
          repo.version_control_agent.get({ location: jhove_output_filepath }, clone_location)
          repo.version_control_agent.unlock({ content: jhove_output_filepath }, clone_location)
        end

        # Runs jhove on `data/assets` stores output in `data/metadata/jhove_output.xml`.
        # Because we unlock the files before running jhove the filename will be
        # used in the jhove output. Otherwise the file's location in git is used.
        jhove_output = JhoveService.new(File.join(clone_location, repo.metadata_subdirectory))
                                   .run_jhove(File.join(clone_location, repo.assets_subdirectory))

        repo.version_control_agent.lock(repo.assets_subdirectory, clone_location)
        repo.version_control_agent.add({:content => "#{repo.metadata_subdirectory}/#{File.basename(jhove_output)}"}, clone_location)
        repo.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.generated_preservation_metadata', object_id: repo.names.fedora), clone_location)
        repo.version_control_agent.push(clone_location)
      end

      def add_preservation_and_mets_xml(clone_location)
        # Create and add preservation.xml to repository
        preservation_filepath = File.join(repo.metadata_subdirectory, repo.preservation_filename)
        mets_filepath = File.join(repo.metadata_subdirectory, METS_FILENAME)

        # If preservation and mets xml files are already present, retrieve and unlock them.
        [preservation_filepath, mets_filepath].each do |relative_path|
          if ExtendedGit.open(clone_location).annex.whereis.includes_file?(relative_path)
            repo.version_control_agent.get({ location: relative_path }, clone_location)
            repo.version_control_agent.unlock({ content: relative_path }, clone_location)
          end
        end

        # Write new xml to files.
        File.write(File.join(clone_location, preservation_filepath), repo.metadata_builder.preservation_xml)
        File.write(File.join(clone_location, mets_filepath), repo.metadata_builder.mets_xml)

        # add, commit, push
        repo.version_control_agent.add({ content: repo.metadata_subdirectory }, clone_location)
        repo.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.write_preservation_xml'), clone_location)
        repo.version_control_agent.push({ content: repo.metadata_subdirectory }, clone_location)

        # Save link to xml files in metadata_builder
        repo.metadata_builder.update(
          generated_metadata_files: {
            "#{preservation_filepath}" => File.join(repo.names.bucket, repo.version_control_agent.look_up_key(preservation_filepath, clone_location)).to_s,
            "#{mets_filepath}" => File.join(repo.names.bucket, repo.version_control_agent.look_up_key(mets_filepath, clone_location)).to_s
          }
        )
      end

      def create_digital_object
        repo = Repo.new(
          human_readable_name: directive,
          metadata_subdirectory: 'metadata',
          assets_subdirectory: 'assets',
          file_extensions: ['tif', 'TIF'],
          metadata_source_extensions: ['csv'],
          preservation_filename: 'preservation.xml',
          new_format: true # Setting to differentiate from previously created repos
        )
        repo.unique_identifier = unique_identifier if unique_identifier
        repo.save!
        repo
      end

      def update_digital_object(repo)
        repo.update!(
          description: 'Generated from CSV through automated workflow',
          last_external_update: Time.current,
          owner: created_by.email
        )
      end

      def copy_assets(clone_location)
        return if assets.empty?
        assets_path = File.join(MountedDrives.path_to(assets[:drive]), assets[:path])
        assets_directory = File.join(clone_location, repo.assets_subdirectory)

        Utilities.copy_files(assets_path, assets_directory, repo.file_extensions)

        repo.version_control_agent.add({}, clone_location)
        repo.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.automated.added_assets'), clone_location)
        repo.version_control_agent.push({}, clone_location)
      end
  end
end
