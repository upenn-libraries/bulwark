module ExtendedGit
  class Annex
    def initialize(base)
      @base = base
    end

    def version(options = {})
      @base.annex_lib.version(options)
    end

    def info(about = nil)
      @base.annex_lib.info(about)
    end

    def init(options = {})
      @base.annex_lib.init(options)
    end

    def get(path)
      @base.annex_lib.get(path)
    end

    def enableremote(name, options = {})
      @base.annex_lib.enableremote(name, options)
    end

    def fsck(options = {})
      @base.annex_lib.fsck(options)
    end

    def drop(path)
      @base.annex_lib.drop(path)
    end

    def testremote(name, options = {})
      @base.annex_lib.testremote(name, options)
    end
  end
end
