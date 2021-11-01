# frozen_string_literal: true

module Bulwark
  class Import
    module MountedDrives
      # Path to where drive is mounted.
      def self.path_to(drive)
        raise "#{drive} not configured" unless valid?(drive)
        all[drive]
      end

      # Returns true if the given drive is configured.
      def self.valid?(drive)
        all.keys.include?(drive) && all[drive].present?
      end

      # Returns true if the given path exists within the drive.
      def self.valid_path?(drive, path)
        return false if drive.blank? || path.blank?
        valid?(drive) && File.exist?(File.join(path_to(drive), path))
      end

      # Returns all configured drives.
      def self.all
        Settings.mounted_drives.to_h.with_indifferent_access
      end
    end
  end
end
