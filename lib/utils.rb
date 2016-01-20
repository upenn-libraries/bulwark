module Utils
  class << self
    def config
      @config ||= Utils::Configuration.new
    end
    def configure
      yield config
    end
  end
end
