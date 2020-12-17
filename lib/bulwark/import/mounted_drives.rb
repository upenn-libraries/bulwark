module Bulwark
  class Import
    module MountedDrives
      # Path to where drive is mounted.
      def self.path_to(drive)
        raise "#{drive} not configured" unless valid?(drive)
        all[drive]
      end

      # Returns true if the given drive is configured
      def self.valid?(drive)
        all.keys.include?(drive)
      end

      # Returns true if the given path exists within the drive.
      def self.valid_path?(drive, path)
        valid?(drive) && File.exist?(File.join(path_to(drive), path))
      end

      # Returns all configured drives
      def self.all
        Rails.application.config_for(:bulwark)['mounted_drives'].with_indifferent_access
      end
    end
  end
end
