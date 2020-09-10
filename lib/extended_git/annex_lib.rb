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
    def init(name, opts = {})
      array_opts = []
      array_opts << "--version=#{opts[:version]}" if opts[:version]

      command("init #{name}", array_opts)
    end

    # De-initialize git-annex and clean out repository.
    def uninit
      command('uninit')
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

    # Adds file to git-annex
    def add(path)
      command("add #{escape(path)}")
    end

    # Makes the content of annexed files available.
    def get(path)
      command("get #{escape(path)}")
    end

    def enableremote(name, opts = {})
      array_opts = []
      array_opts << "directory=#{opts[:directory]}" if opts[:directory]

      command("enableremote #{name}", array_opts)
    end

    def initremote(name, opts = {})
      array_opts = []
      array_opts << "type=#{opts[:type]}"            if opts[:type]
      array_opts << "directory=#{opts[:directory]}"  if opts[:directory]
      array_opts << "encryption=#{opts[:encryption]}" if opts[:encryption]

      command("initremote #{name}", array_opts)
    end

    def fsck(opts = {})
      array_opts = []
      array_opts << "--from=#{opts[:from]}" if opts[:from]
      array_opts << "--fast" if opts[:fast]

      command('fsck', array_opts)
    end

    # Removes content of files from repository.
    def drop(path = nil, opts = {})
      array_opts = []
      array_opts << "--all" if opts[:all]
      array_opts << "--force" if opts[:force]

      command("drop #{escape(path)}", array_opts)
    end

    def testremote(name, opts = {})
      array_opts = []
      array_opts << '--fast' if opts[:fast]

      command("testremote #{name}", array_opts)
    end

    # Returns information about where files are located.
    def whereis(path = nil, opts = {})
      array_opts = []
      array_opts << '--json'     if opts[:json]
      array_opts << '--unlocked' if opts[:unlocked]
      array_opts << '--locked'   if opts[:locked]

      command("whereis #{path}", array_opts)
    end

    # Returns repository information.
    def info(about = nil, **opts)
      array_opts = []
      array_opts << '--json'     if opts[:json]

      command("info #{about}", array_opts)
    end

    def unlock(path = nil)
      command("unlock #{escape(path)}")
    end

    def lock(path = nil)
      command("lock #{escape(path)}")
    end

    def sync(opts = {})
      array_opts = []
      array_opts << '--content' if opts[:content]

      command('sync', array_opts)
    end

    def copy(path, opts = {})
      array_opts = []
      array_opts << "--to=#{opts[:to]}" if opts[:to]

      command("copy #{escape(path)}", array_opts)
    end

    private

      # Only escape non-nil values.
      def escape(value)
        value.nil? ? nil : value.shellescape
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
