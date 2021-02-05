# frozen_string_literal: true

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
        all.keys.include?(drive) && all[drive].present?
      end

      # Returns true if the given path exists within the drive.
      def self.valid_path?(drive, path)
        Rails.logger.error("all: #{all}")
        return false if drive.blank? || path.blank?
        Rails.logger.error("fullpath: #{File.join(path_to(drive), path)}")
        valid?(drive) && File.exist?(File.join(path_to(drive), path))
      end

      # Returns all configured drives
      def self.all
        Rails.application.config_for(:bulwark)['mounted_drives']
      end
    end
  end
end
