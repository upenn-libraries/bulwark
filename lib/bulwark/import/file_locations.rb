# frozen_string_literal: true
module Bulwark
  class Import
    class FileLocations
      attr_reader :drive, :relative_paths, :errors

      def initialize(options = {})
        options = options.deep_symbolize_keys

        @drive = options[:drive]
        @relative_paths = Array.wrap(options[:path]).delete_if(&:blank?)

        @errors = []
      end

      # Check that the configuration contains all the necessary
      # information. This does not check the validity of the paths
      def valid?
        @errors << "drive invalid: '#{drive}'" if drive && !MountedDrives.valid?(drive)
        @errors << "must contain at least one path" if relative_paths.empty?

        errors.empty?
      end

      # Checks that the given paths are valid paths.
      #
      # @return [FalseClass] if there are no assets paths or if one of them is invalid
      # @return [TrueClass] if there are asset paths present and they are all valid
      def valid_paths?
        !relative_paths.empty? && relative_paths.all? { |p| MountedDrives.valid_path?(drive, p) }
      end

      # Return absolute paths were assets are located on mounted drives. If drive or
      # paths are not provided returns an empty array.
      #
      # @return [Array<String>] list of paths
      def absolute_paths
        return [] unless valid?
        drive_path = MountedDrives.path_to(drive)
        relative_paths.map { |p| File.join(drive_path, p) }
      end

      # Returns an aggregated list of all the files available at all the files
      # paths given. Only filenames are returned.
      #
      # @return [Array<String>]
      def files_available
        absolute_paths.map { |path| files_at(path) }.flatten
      end

      private

        # Returns a list of files available at the given path
        def files_at(path)
          if File.directory?(path)
            Dir.glob(File.join(path, '*')).map { |f| File.basename(f) }
          else
            [File.basename(path)]
          end
        end
    end
  end
end
