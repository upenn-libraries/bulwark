# ExtendedGit::Base delegates all the methods implemented in Git::Base, therefore
# supporting git methods and git-annex methods.

module ExtendedGit
  class Base < DelegateClass(Git::Base)

    def initialize(options = {})
      raise ExtendedGit::Error, 'git-annex is not installed.' unless ExtendedGit.git_annex_installed?
      super(options)
    end

    # Methods for git annex:
    #   annex.version
    #   annex.init
    #   annex.info
    #   annex.get
    #   annex.initremote
    #   annex.enableremote
    #   annex.testremote
    def annex
      ExtendedGit::Annex.new(self)
    end

    def annex_lib
      @annex_lib ||= ExtendedGit::AnnexLib.new(self)
    end
  end
end
