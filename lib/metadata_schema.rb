module MetadataSchema

  class << self

    def config
      @config ||= MetadataSchema::Configuration.new
    end

    def configure
      yield config
    end
  end
end
