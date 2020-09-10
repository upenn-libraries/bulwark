# ExtendedGit::Base delegates all the methods implemented in Git::Base, therefore
# supporting git methods and git-annex methods.

module ExtendedGit
  class Base < DelegateClass(Git::Base)

    def initialize(obj)
      raise ExtendedGit::Error, 'git-annex is not installed.' unless ExtendedGit.git_annex_installed?
      super(obj)
    end

    # Methods for git annex:
    #   annex.version
    #   annex.init
    #   annex.uninit
    #   annex.info
    #   annex.get
    #   annex.sync
    #   annex.unlock
    #   annex.lock
    #   annex.whereis
    #   annex.initremote
    #   annex.enableremote
    #   annex.testremote
    def annex
      @annex ||= ExtendedGit::Annex.new(self)
    end
  end
end
