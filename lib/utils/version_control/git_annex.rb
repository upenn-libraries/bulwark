require 'git'
require 'shellwords'

module Utils
  module VersionControl
    class GitAnnex

      attr_accessor :remote_repo_path, :working_repo_path

      def initialize(repo, path_namespace)
        @repo = repo
        @remote_repo_path = "#{Utils.config[:assets_path]}/#{@repo.names.git}"
        @working_repo_path = "#{path_namespace}/#{@repo.names.git}"
      end

      def repo
        @repo ||= ''
      end

      def initialize_bare_remote
        `git init --bare #{@remote_repo_path}`
        Dir.chdir(@remote_repo_path)
        `git annex init origin`
        `git config annex.largefiles 'not (include=.repoadmin/bin/*.sh)'`
        rolling_upgrade(@remote_repo_path)
        init_special_remote(@remote_repo_path, 's3', @repo.unique_identifier)
      end

      def set_remote_permissions
        FileUtils.chmod_R(Utils.config[:remote_repo_permissions], @remote_repo_path)
      end

      def clone(options = {})
        destination = options[:destination].present? ? options[:destination] : @working_repo_path
        fsck = options[:fsck].nil? ? true : options[:fsck]
        begin
          Git.clone(@remote_repo_path, destination)
          init_clone(destination, fsck)
        rescue => exception
          raise Utils::Error::VersionControl.new(error_message(exception.message))
        end
        destination
      end

      def reset_hard(dir = @working_repo_path)
        change_dir_working(dir)
        `git reset --hard`
      end

      def sync(dir = @working_repo_path, options = '')
        begin
          change_dir_working(dir)
          rolling_upgrade(dir)
          `git annex sync #{options}`
        rescue
          raise I18n.t('colenda.utils.version_control.git_annex.errors.sync')
        end
      end

      def push_bare
        change_dir_working(@working_repo_path)
        `git push origin master`
      end

      def push
        change_dir_working(@working_repo_path)
        `git push origin master git-annex`
        `git annex sync --content`
      end

      def pull(dir = @working_repo_path)
        change_dir_working(dir)
        `git pull`
      end

      def add(options)
        content = options[:content].present? ? options[:content] : '.'
        add_type = options[:add_type].present? ? options[:add_type] : :store
        return `git annex add #{Shellwords.escape(content)}` if add_type == :store
        return `git add #{Shellwords.escape(content)}` if add_type == :git
      end

      def copy(options)
        content = options[:content].present? ? options[:content] : '.'
        to = options[:to].present? ? "--to #{options[:to]}" : ''
        from = options[:from].present? ? "--from #{options[:from]}" : ''
        return `git annex copy #{Shellwords.escape(content)} #{from} #{to}`
      end


      def commit(commit_message)
        change_dir_working(@working_repo_path)
        working_repo = Git.open(@working_repo_path)
        begin
          working_repo.commit(commit_message)
        rescue => exception
          return if exception.message =~ /nothing \w* commit, working \w* clean/ or exception.message =~ /Changes not staged for commit/ or exception.message == 'Nothing staged for commit.'
          raise Utils::Error::VersionControl.new(error_message(exception.message))
        end
      end

      def commit_bare(commit_message)
        working_repo = Git.open(@working_repo_path)
        working_repo.add(:all => true)
        working_repo.commit(commit_message)
      end

      def remove_working_directory
        `git config annex.pidlock true`
        `git annex drop --all --force`
        Dir.chdir(Rails.root.to_s)
        parent_dir = @working_repo_path.gsub(repo.names.git,"")
        FileUtils.rm_rf(parent_dir, :secure => true) if File.directory?(parent_dir)
      end

      def get(dir = @working_repo_path)
        _get_drop_calls(dir, 'get')
      end

      def drop(dir = @working_repo_path)
        _get_drop_calls(dir, 'drop')
      end

      def unlock(options)
        raise Utils::Error::VersionControl.new(I18n.t('colenda.utils.version_control.git_annex.errors.unlock_no_options')) unless options[:content].present?
        dir = options[:location].present? ? options[:location] : @working_repo_path
        change_dir_working(dir)
        `git annex unlock #{Shellwords.escape(options[:content])}`
      end

      def lock(file = '.')
        change_dir_working(@working_repo_path)
        `git annex lock #{Shellwords.escape(file)}`
      end

      def look_up_key(path, dir = @working_repo_path)
        change_dir_working(dir) unless Dir.pwd == dir
        `git annex lookupkey #{path.gsub(dir, '')}`.chomp
      end

      def rolling_upgrade(dir = @working_repo_path)
        change_dir_working(dir) unless Dir.pwd == dir
        version_string = `git annex version`
        unless version_string.include?("local repository version: #{Utils.config[:supported_vca_version]}")
          `git annex upgrade` if git_annex_upgrade_supported(version_string)
        end
      end

      def init_special_remote(dir = @working_repo_path, remote_type, remote_name)
        change_dir_working(dir) unless Dir.pwd == dir
        raise 'Missing S3 special remote environment variables' unless Utils::Storage::Ceph.required_configs?
        `export AWS_ACCESS_KEY_ID=#{Utils::Storage::Ceph.config.aws_access_key_id}; export AWS_SECRET_ACCESS_KEY=#{Utils::Storage::Ceph.config.aws_secret_access_key};  git annex initremote #{Utils::Storage::Ceph.config.special_remote_name} type=#{Utils::Storage::Ceph.config.storage_type} encryption=#{Utils::Storage::Ceph.config.encryption} requeststyle=#{Utils::Storage::Ceph.config.request_style} host=#{Utils::Storage::Ceph.config.host} port=#{Utils::Storage::Ceph.config.port} public=#{Utils::Storage::Ceph.config.public} bucket='#{remote_name.bucketize}'
` if remote_type == 's3'
      end

      def init_clone(dir = @working_repo_path, fsck = true)
        Dir.chdir(dir)
        `git annex init --version=#{Utils.config[:supported_vca_version]}`
        `git annex enableremote #{Utils::Storage::Ceph.config.special_remote_name}`
        `git config remote.origin.annex-ignore true`
        `git config annex.pidlock true`
        `git config annex.largefiles 'not (include=.repoadmin/bin/*.sh)'`
        `git annex fsck --from #{Utils::Storage::Ceph.config.special_remote_name} --fast` if fsck
      end

      private

      def change_dir_working(dir = @working_repo_path)
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
        dir = Shellwords.escape(dir)
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

    end
  end
end