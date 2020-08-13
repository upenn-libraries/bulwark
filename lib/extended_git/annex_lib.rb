require 'open3'

module ExtendedGit
  class AnnexLib
    def initialize(base = nil)
      @git_dir = nil
      @git_index_file = nil
      @git_work_dir = nil

      if base
        @git_dir = base.repo.path
        @git_index_file = base.index.path if base.index
        @git_work_dir = base.dir.path if base.dir
      end
    end

    # Initialize git annex in a repository.
    #
    # accepts options:
    #   :version (with version number)
    #   :autoenable
    def init(opts = {})
      array_opts = []
      array_opts << "--version=#{opts[:version]}" if opts[:version]
      array_opts << "--autoenable" if opts[:autoenable]

      command('init', array_opts)
    end

    # Returns version of git-annex running and repository version information.
    #
    # accepts options:
    #  :raw
    def version(opts = {})
      array_opts = []
      array_opts << '--raw' if opts[:raw]

      command('version', array_opts)
    end

    # Returns information about an item or repository
    def info(about = nil)
      command("info #{about}")
    end

    # Makes the content of annexed files available.
    def get(path)
      command("get #{path}")
    end

    def enableremote(name, opts = {})
      array_opts = []
      array_opts << "directory=#{opts[:directory]}" if opts[:directory]

      command("enableremote #{name}", array_opts)
    end

    def fsck(opts = {})
      array_opts = []
      array_opts << "--from=#{opts[:from]}" if opts[:from]
      array_opts << "--fast" if opts[:fast]

      command('fsck', array_opts)
    end

    # Removes content of files from repository.
    def drop(path)
      command("drop #{path}")
    end

    def testremote(name, opts = {})
      array_opts = []
      array_opts << '--fast' if opts[:fast]

      command("testremote #{name}", array_opts)
    end

    # Run a git annex command. This method takes a lot of inspiration from
    # the `command` method in `Git::Lib`.
    def command(cmd, opts = [])
      # TODO:global config, pointing at correct working path and git dir
      global_opts = []
      global_opts << "--git-dir=#{@git_dir}" if !@git_dir.nil?
      global_opts << "--work-tree=#{@git_work_dir}" if !@git_work_dir.nil?

      global_opts = global_opts.flatten.join(' ') # TODO: should be escaped?

      opts = [opts].flatten.join(' ') # TODO: should be escaped?

      git_cmd = "git #{global_opts} annex #{cmd} #{opts}"
      output, status = Open3.capture2e(git_cmd)
      exitstatus = status.exitstatus

      # Potentially might have to revisit this to not raise errors when status
      # code is 1 and there is no output. See `Git::Lib#command` implementation.
      if exitstatus != 0
        raise ExtendedGit::Error.new(git_cmd + ':' + output)
      end

      output
    end
  end
end
