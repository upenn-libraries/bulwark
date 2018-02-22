module ModelNamingExtensions

  class Name

    attr_reader :git, :directory, :human, :fedora, :filename, :bucket

    def initialize(object)
      @human = object.human_readable_name
      @directory = object.human_readable_name.end_with?(object.unique_identifier) ? "#{Utils.config[:repository_prefix]}_#{object.human_readable_name}".directorify : "#{Utils.config[:repository_prefix]}_#{object.human_readable_name}_#{object.unique_identifier}".directorify
      @git = @directory.gitify
      @fedora = object.unique_identifier.fedorafy
      @filename = @directory.filename_sanitize
      @bucket = object.unique_identifier.bucketize
    end

  end

  module Naming

    def names
      ModelNamingExtensions::Name.new(self)
    end

  end

end

