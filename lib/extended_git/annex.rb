module ExtendedGit
  class Annex
    def initialize(base)
      @base = base
    end

    def version(options = {})
      lib.version(options)
    end

    def init(name = nil, **options)
      lib.init(name, options)
    end

    def uninit
      lib.uninit
    end

    def get(path)
      lib.get(path)
    end

    def add(path, **options)
      lib.add(path, options)
    end

    def initremote(name, options = {})
      lib.initremote(name, options)
    end

    def enableremote(name, options = {})
      lib.enableremote(name, options)
    end

    def fsck(options = {})
      lib.fsck(options)
    end

    def drop(path = nil, **options)
      lib.drop(path, options)
    end

    def sync(options = {})
      lib.sync(options)
    end

    def copy(path, options = {})
      lib.copy(path, options)
    end

    def testremote(name, options = {})
      lib.testremote(name, options)
    end

    def unlock(path = nil)
      lib.unlock(path)
    end

    def lock(path = nil)
      lib.lock(path)
    end

    def lookupkey(path)
      lib.lookupkey(path)
    end

    def whereis(path = nil, **options)
      WhereIs.new(@base, path, options)
    end

    def info
      RepositoryInfo.new(@base)
    end

    def lib
      @lib ||= ExtendedGit::AnnexLib.new(@base)
    end
  end
end
