module Bulwark
  class Import
    module Utilities
      # Rsyncing files from one location to another. If the source path is a
      # directory all the contents within that directory are copied to the new
      # location, if it's a file only that file will be copied over to the new location.
      def self.copy_files(source, destination, extensions)
        raise Error, "#{source} not found" unless File.exists?(source)

        # Adding a trailing slash if source is a directory to copy all contents
        # within the directory and not the directory itself.
        source = File.join(source, '/') if File.directory?(source)

        flags = extensions.map { |ext| "--include=*.#{ext}" } + ['--exclude="*"']
        # Not preserving owner or group because it causes errors if the group/user
        # is not present in the drive we are transfering the files to. The owner/group
        # of the files is changed later anyways.
        Rsync.run(source, destination, "-av --no-owner --no-group #{flags.join(' ')}") do |result|
          if result.success?
            result.changes.each do |change|
              Rails.logger.info "#{change.filename} (#{change.summary})"
            end
            result
          else
            raise Error, "Problem rsync'ing content: #{result.error}"
          end
        end
      end

      # Queries EZID to check if a given ark already exists.
      #
      # @return true if ark exists
      # @return false if ark does not exist
      def self.ark_exists?(ark)
        Ezid::Identifier.find(ark)
        true
      rescue Ezid::Error => e
        false
      end
    end
  end
end
