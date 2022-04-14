# frozen_string_literal: true
module DigitalObject
  module Derivatives
    # Map of mime_types to valid derivative extensions.
    DERIVATIVE_EXTENSIONS = {
      'mov' => 'mp4',
      'audio/vnd.wave' => 'mp3'
    }
    ACCESS = 'access'
    THUMBNAILS = 'thumbnails'
    TYPES = [ACCESS, THUMBNAILS]

    extend ActiveSupport::Concern

    def copy_and_link_derivatives(type, paths)
      raise 'Invalid derivative type' unless TYPES.include?(type)

      create_derivative_subdirectories

      return unless type == ACCESS # Only supporting external import of access copy derivatives

      # Copy over derivatives and add them to the repository
      paths.each do |path|
        Bulwark::FileUtilities.copy_files(path, access_dir_path, DERIVATIVE_EXTENSIONS.values)
      end

      version_control_agent.add({ content: access_dir_path, include_dotfiles: true  }, clone_location)
      version_control_agent.commit('Access derivatives added via bulk import', clone_location)
      version_control_agent.push({ content: access_dir_path }, clone_location)

      # Link derivatives
      assets.each do |asset|
        next unless DERIVATIVE_EXTENSIONS.keys.include? asset.mime_type

        derivative_extension = DERIVATIVE_EXTENSIONS[asset.mime_type]

        access_derivative_path = File.join(access_dir_path, "#{File.basename(asset.filename, '.*')}.#{derivative_extension}")
        access_derivative_relative_path = Pathname.new(access_derivative_path).relative_path_from(Pathname.new(clone_location)).to_s

        if File.exist?(access_derivative_path)
          asset.access_file_location = clone.annex.lookupkey(access_derivative_relative_path)
          asset.save!
        end
      end
    end

    def access_dir_path
      File.join(clone_location, derivatives_subdirectory, ACCESS)
    end

    def thumbnail_dir_path
      File.join(clone_location, derivatives_subdirectory, THUMBNAILS)
    end

    # Generate derivatives for jpeg and tiff files, for audio files look for derivatives and link them.
    # For now, we are not generating derivatives for audio files, thought it is something we will need to add
    # in the future.
    def generate_derivatives
      # TODO: check that there are images present before downloading all the derivatives
      create_derivative_subdirectories

      # Create derivatives for jpeg and tiff files. For any audio files, link any assets, that are found.
      assets.each do |asset|
        if asset.mime_type == 'image/jpeg' || asset.mime_type == 'image/tiff'
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
      end

      metadata_builder.update!(last_file_checks: DateTime.current)

      version_control_agent.lock(derivatives_subdirectory, clone_location)
      version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.generated_all_derivatives', object_id: names.fedora), clone_location)
      version_control_agent.push({ content: derivatives_subdirectory }, clone_location)
    end

    private

    def create_derivative_subdirectories
      get_and_unlock(derivatives_subdirectory)

      # Create 'thumbnails' and 'access' directories if they aren't present already.
      [access_dir_path, thumbnail_dir_path].each do |dir|
        FileUtils.mkdir(dir) unless File.exist?(dir)
      end
    end
  end
end
