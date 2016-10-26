module ModelNamingExtensions

  class Name

    attr_reader :git, :directory, :human

    def initialize(object)
      @human = object.human_readable_name
      @directory = object.human_readable_name.directorify
      @git = object.human_readable_name.gitify
    end

  end

  module Naming

    def self.extended(base)
      base.remove_possible_method :names
      base.delegate :names, to: :class
    end

    def names
      ModelNamingExtensions::Name.new(self)
    end

  end

end

