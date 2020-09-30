require 'git'
require 'shellwords'

module Utils
  module VersionControl
    class GitAnnex

      attr_accessor :remote_repo_path, :working_repo_path

      def initialize(repo)
        @repo = repo
        @remote_repo_path = "#{Utils.config[:assets_path]}/#{@repo.names.git}"
        @working_repo_path = ''
      end

      def repo
        @repo ||= ''
      end

      def initialize_bare_remote
        `git init --bare --shared=group #{@remote_repo_path}` # `shared` option currently not supported by ruby-git
        git = ExtendedGit.bare(@remote_repo_path)
        git.annex.init('origin')
        git.config('annex.largefiles', 'not (include=.repoadmin/bin/*.sh)')
        init_special_remote(@remote_repo_path, Utils.config[:special_remote][:type], @repo.unique_identifier)
      end

      def set_remote_permissions
        FileUtils.chmod_R(Utils.config[:remote_repo_permissions], @remote_repo_path)
      end

      def clone(options = {})
        working_path_namespace = path_namespace
        FileUtils.mkdir_p(working_path_namespace)
        @working_repo_path = "#{working_path_namespace}/#{@repo.names.git}"
        destination = options[:destination].present? ? options[:destination] : @working_repo_path
        fsck = options[:fsck].nil? ? true : options[:fsck]
        begin
          ExtendedGit.clone(@remote_repo_path, destination)
          init_clone(destination, fsck)
        rescue => exception
          raise Utils::Error::VersionControl.new(error_message(exception.message))
        end
        destination
      end

      def push(options, dir)
        git = ExtendedGit.open(dir)
        git.push('origin', 'master')
        git.push('origin', 'git-annex')

        if options[:content].present?
          git.annex.copy(options[:content], to: Utils.config[:special_remote][:name])
        else
          git.annex.sync(content: true)
        end
      end

      # My current understanding (for git-annex 8) is that all files added either by `git add` or
      # `git annex add` are added via git-annex as long as they meet the requirements
      # set in `annex.largefiles` and aren't dotfiles. Dotfiles are automatically
      # controlled by git instead of git annex unless configured otherwise. Based
      # on our current set up that would be mean any files except for
      # `/.repoadmin/bin/init.sh` will be added through git-annex.
      #
      # See https://git-annex.branchable.com/forum/__34__git_add__34___vs___34__git_annex_add__34___in_v6/
      #
      # TLDR; We probably no longer need to specify which files are to be stored in git
      # vs git annex.
      def add(options, dir)
        content = options[:content].present? ? options[:content] : '.'
        add_type = options[:add_type].present? ? options[:add_type] : :store
        include_dotfiles = options[:include_dotfiles] || false
        git = ExtendedGit.open(dir)
        return git.annex.add(content, include_dotfiles: include_dotfiles) if add_type == :store
        return git.add(content) if add_type == :git
      end

      def copy(options, dir)
        git = ExtendedGit.open(dir)
        content = options[:content] || '.'
        git.annex.copy(content, to: options[:to])
      end

      def commit(commit_message, dir)
        working_repo = Git.open(dir)
        begin
          working_repo.commit(commit_message)
        rescue => exception
          return if exception.message =~ /nothing \w* commit, working \w* clean/ or exception.message =~ /Changes not staged for commit/ or exception.message == 'Nothing staged for commit.'
          raise Utils::Error::VersionControl.new(error_message(exception.message))
        end
      end

      # TODO: Using `FileUtils.rm_rf` does not raise StandardErrors. We might want to
      # at least log those errors, if we don't want them raised.
      #
      # TODO: We might want to `git annex uninit` before we delete a cloned repository
      # because that way, the repository is removed from the list of repositories
      # when doing a `git annex info` and the `.git/annex` directory
      # and its contents are completely deleted.
      #
      def remove_working_directory(dir)
        git = ExtendedGit.open(dir)
        git.config('annex.pidlock', 'true')
        git.annex.drop(all: true, force: true) # Not sure we have to be so forceful here.

        Dir.chdir(Rails.root.to_s) # FIXME: Ensure we are not in the directory we want to delete; eventually can delete.
        parent_dir = dir.gsub(repo.names.git, "")
        FileUtils.rm_rf(parent_dir, secure: true) if File.directory?(parent_dir)
      end

      def get(options, dir)
        get_dir = options[:location].present? ? options[:location] : '.'
        git = ExtendedGit.open(dir)
        git.annex.get(get_dir)
      end

      def drop(options = {}, dir)
        content = options[:content].present? ? options[:content] : '.'
        git = ExtendedGit.open(dir)
        git.annex.drop(content)
        change_perms(File.basename(dir)) if ENV['IMAGING_USER'].present? # This might be in preperation for deleting the file. Should probably be moved.
      end

      def unlock(options, dir)
        raise ArgumentError, 'Utils::VersionControl::GitAnnex#unlock no longer supports location parameter' if options[:location]
        raise Utils::Error::VersionControl.new(I18n.t('colenda.utils.version_control.git_annex.errors.unlock_no_options')) unless options[:content].present?

        git = ExtendedGit.open(dir)
        git.annex.unlock(options[:content])
      end

      def lock(file = '.', dir)
        git = ExtendedGit.open(dir)
        git.annex.lock(file)
      end

      # @return [String] return git-annex key
      def look_up_key(path, dir)
        git = ExtendedGit.open(dir)
        git.annex.lookupkey(path)
      end

      def init_special_remote(dir, remote_type, remote_name)
        change_dir_working(dir) unless Dir.pwd == dir
        case remote_type
        when 'S3'
          raise 'Missing S3 special remote environment variables' unless Utils::Storage::Ceph.required_configs?
          `export AWS_ACCESS_KEY_ID=#{Utils::Storage::Ceph.config.aws_access_key_id}; export AWS_SECRET_ACCESS_KEY=#{Utils::Storage::Ceph.config.aws_secret_access_key};  git annex initremote #{Utils::Storage::Ceph.config.special_remote_name} type=#{Utils::Storage::Ceph.config.storage_type} encryption=#{Utils::Storage::Ceph.config.encryption} requeststyle=#{Utils::Storage::Ceph.config.request_style} host=#{Utils::Storage::Ceph.config.host} port=#{Utils::Storage::Ceph.config.port} public=#{Utils::Storage::Ceph.config.public} bucket='#{remote_name.bucketize}'`
        when 'directory'
          special_remote = Utils.config[:special_remote]
          raise 'Missing config for Directory special remote' unless special_remote[:name] && special_remote[:directory]

          special_remote_directory = File.join(special_remote[:directory], remote_name.bucketize)
          FileUtils.mkdir_p(special_remote_directory) unless File.directory?(special_remote_directory) # Creates directory if not already present
          `git annex initremote #{special_remote[:name]} type=directory directory=#{special_remote_directory} encryption=none`
        else
          raise ArgumentError, "Special remote type: \"#{remote_type}\" is invalid."
        end
        Dir.chdir(Rails.root.to_s) # FIXME: Eventually remove, when we don't depend on changing the directory
      end

      # Almost identical to docker/init.sh
      def init_clone(dir, fsck = true)
        git = ExtendedGit.open(dir)
        ignore_system_generated_files(dir)
        git.annex.init(version: Utils.config[:supported_vca_version])

        special_remote = Utils.config[:special_remote]
        case special_remote[:type]
        when 'S3'
          git.annex.enableremote(special_remote[:name])
        when 'directory'
          git.annex.enableremote(special_remote[:name], directory: File.join(special_remote[:directory], @repo.unique_identifier.bucketize))
        else
          raise "Special remote type not implemented #{special_remote[:type]}"
        end

        git.config('remote.origin.annex-ignore', 'true') # Does not store binary files in origin remote
        git.config('annex.pidlock', 'true') if special_remote[:top_level_pid_lock]
        git.config('annex.largefiles', 'not (include=.repoadmin/bin/*.sh)')
        git.annex.fsck(from: special_remote[:name], fast: true) if fsck
      end

      private

      # Ignore .nfs* files automatically generated and needed by the nfs store.
      # By using `.git/info/exclude` we can exclude the files in the
      # working directory without adding a `.gitignore` to the repo.
      def ignore_system_generated_files(dir)
        exclude_path = File.join(dir, '.git', 'info', 'exclude')
        File.open(exclude_path, 'w') { |f| f.write('.nfs*') } # Ignore `.nfs* files
      end

      def change_dir_working(dir)
        directory = get_directory(dir)
        begin
          Dir.chdir(directory)
        rescue
          raise I18n.t('colenda.utils.version_control.git_annex.errors.missing_directory', :directory => directory)
        end
      end

      def get_directory(directory_string)
        File.directory?(directory_string) ? directory_string : File.dirname(directory_string)
      end

      def error_message(message)
        case(message)
          when /no changes/
            error_message = I18n.t('colenda.utils.version_control.git_annex.errors.no_changes')
          when /does not exist/
            error_message = I18n.t('colenda.utils.version_control.git_annex.errors.does_not_exist')
          when /already exists and is not an empty directory/
            error_message = I18n.t('colenda.utils.version_control.git_annex.errors.leftover_clone', :directory => @working_repo_path)
          else
            error_message = I18n.t('colenda.utils.version_control.git_annex.errors.generic', :error_message => message)
        end
        error_message
      end

      def path_seed
        Digest::SHA256.hexdigest("#{repo.names.git}#{SecureRandom.uuid}")
      end

      def path_namespace
        "#{Utils.config[:workspace]}/#{path_seed}"
      end

      def change_perms(repo)
        FileUtils.chown_R(ENV['IMAGING_USER'], ENV['IMAGING_USER'], "#{Utils.config['assets_path']}/#{repo}")
      end
    end
  end
end
