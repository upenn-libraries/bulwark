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
        `git init --bare --shared=group #{@remote_repo_path}`
        Dir.chdir(@remote_repo_path)
        `git annex init origin`
        `git config annex.largefiles 'not (include=.repoadmin/bin/*.sh)'`
        rolling_upgrade(@remote_repo_path)
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

      def reset_hard(dir)
        change_dir_working(dir)
        `git reset --hard`
      end

      def sync(dir)
        begin
          change_dir_working(dir)
          rolling_upgrade(dir)
          `git annex sync --content`
        rescue
          raise I18n.t('colenda.utils.version_control.git_annex.errors.sync')
        end
      end

      def push_bare(dir)
        change_dir_working(dir)
        `git push origin master`
      end

      def push(options, dir)
        change_dir_working(dir)
        content = options[:content].present? ? options[:content] : nil
        `git push origin master git-annex`
        if content.present?
          `git annex copy #{Shellwords.escape(content)} --to=#{Utils.config[:special_remote][:name]}`
        else
          `git annex sync --content`
        end
      end

      def pull(dir)
        change_dir_working(dir)
        `git pull`
      end

      def add(options, dir)
        change_dir_working(dir)
        content = options[:content].present? ? options[:content] : '.'
        add_type = options[:add_type].present? ? options[:add_type] : :store
        return `git annex add #{Shellwords.escape(content)}` if add_type == :store # TODO: this hangs
        return `git add #{Shellwords.escape(content)}` if add_type == :git
      end

      def copy(options, dir)
        change_dir_working(dir)
        content = options[:content].present? ? options[:content] : '.'
        to = options[:to].present? ? "--to #{options[:to]}" : ''
        from = options[:from].present? ? "--from #{options[:from]}" : ''
        return `git annex copy #{Shellwords.escape(content)} #{from} #{to}`
      end


      def commit(commit_message, dir)
        change_dir_working(dir)
        working_repo = Git.open(dir)
        begin
          working_repo.commit(commit_message)
        rescue => exception
          return if exception.message =~ /nothing \w* commit, working \w* clean/ or exception.message =~ /Changes not staged for commit/ or exception.message == 'Nothing staged for commit.'
          raise Utils::Error::VersionControl.new(error_message(exception.message))
        end
      end

      def commit_bare(commit_message, dir)
        working_repo = Git.open(dir)
        working_repo.add(:all => true)
        working_repo.commit(commit_message)
      end

      def remove_working_directory(dir)
        `git config annex.pidlock true`
        `git annex drop --all --force`
        Dir.chdir(Rails.root.to_s)
        parent_dir = dir.gsub(repo.names.git,"")
        FileUtils.rm_rf(parent_dir, :secure => true) if File.directory?(parent_dir)
      end

      def get(options, dir)
        change_dir_working(dir)
        get_dir = options[:location].present? ? options[:location] : dir
        _get_drop_calls(get_dir, 'get')
      end

      def drop(options = {}, dir)
        change_dir_working(dir)
        drop = options[:content].present? ? options[:content] : '.'
        `git annex drop #{Shellwords.escape(options[:content])}`
        change_perms(File.basename(dir)) if ENV['IMAGING_USER'].present?
      end

      def unlock(options, dir)
        raise Utils::Error::VersionControl.new(I18n.t('colenda.utils.version_control.git_annex.errors.unlock_no_options')) unless options[:content].present?
        dir = options[:location].present? ? options[:location] : dir
        change_dir_working(dir)
        `git annex unlock #{Shellwords.escape(options[:content])}`
      end

      def lock(file = '.', dir)
        change_dir_working(dir)
        `git annex lock #{Shellwords.escape(file)}`
      end

      def look_up_key(path, dir)
        change_dir_working(dir) unless Dir.pwd == dir
        dir = dir.ends_with?('/') ? dir : "#{dir}/"
        `git annex lookupkey #{path.gsub(dir, '')}`.chomp
      end

      def rolling_upgrade(dir)
        change_dir_working(dir) unless Dir.pwd == dir
        version_string = `git annex version`
        unless version_string.include?("local repository version: #{Utils.config[:supported_vca_version]}")
          `git annex upgrade` if git_annex_upgrade_supported(version_string)
        end
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
      end

      # Almost identical to docker/init.sh
      def init_clone(dir, fsck = true)
        git = ExtendedGit.open(dir)
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

      def _get_drop_calls(dir, action)
        dir = Dir.exist?(Shellwords.escape(dir)) ? Shellwords.escape(dir) : dir
        if File.directory?(dir)
          Dir.chdir(dir)
          rolling_upgrade(dir)
          `git annex #{action} .`
        else
          Dir.chdir(File.dirname(dir))
          rolling_upgrade(dir)
          `git annex #{action} #{File.basename(dir)}`
        end
      end

      def git_annex_upgrade_supported(version_string)
        sample_local_version = 'local repository version: x'
        local_version_index = version_string.index /local repository version: [aA-z0-9]/
        local_version_number = version_string[local_version_index..(local_version_index + sample_local_version.length-1)].last.to_i
        output_array = version_string.split("\n")
        supported_version_numbers = _version_numbers(output_array, ':', 'supported repository versions:')
        upgradable_version_numbers = _version_numbers(output_array, ':', 'upgrade supported from repository versions:')
        supported_version_numbers.include?(Utils.config[:supported_vca_version]) && upgradable_version_numbers.include?(local_version_number)
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

      def _version_numbers(output_array, split_char, string_to_search)
        versions_line = output_array[output_array.index{|s| s.start_with?(string_to_search)}]
        versions_line.split("#{split_char}").last.lstrip.split(' ').map(&:to_i)
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
