module ModelNamingExtensions

  class Name

    attr_reader :git, :directory, :human

    def initialize(object)
      @human = object.human_readable_name
      @directory = "#{Utils.config[:repository_prefix]}_#{object.human_readable_name}_#{object.unique_identifier}".directorify
      @git = object.human_readable_name.gitify
    end

  end

  module Naming

    def names
      ModelNamingExtensions::Name.new(self)
    end

  end

end

