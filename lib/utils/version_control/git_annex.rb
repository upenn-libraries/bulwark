require 'git'
require 'shellwords'

module Utils
  module VersionControl
    class GitAnnex

      attr_accessor :remote_repo_path, :working_repo_path

      def initialize(repo)
        @repo = repo
        @remote_repo_path = "#{Utils.config[:assets_path]}/#{@repo.names.git}"
        @working_repo_path = "#{Dir.mktmpdir}/#{@repo.names.git}"
      end

      def repo
        @repo ||= ''
      end

      def initialize_bare_remote
        `git init --bare #{@remote_repo_path}`
        Dir.chdir(@remote_repo_path)
        `git annex init origin`
        rolling_upgrade(@remote_repo_path)
      end

      def clone(destination = @working_repo_path)
        begin
          Git.clone(@remote_repo_path, destination)
        rescue => exception
          raise Utils::Error::VersionControl.new(error_message(exception.message))
        end
        destination
      end

      def reset_hard
        working_repo = Git.open(@working_repo_path)
        working_repo.reset_hard
      end

      def sync(dir = @working_repo_path, options = '')
        begin
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

      def add(dir = @working_repo_path)
        _get_drop_calls(dir, 'add')
      end

      def commit(commit_message)
        change_dir_working(@working_repo_path)
        working_repo = Git.open(@working_repo_path)
        #TODO: Consider removing -- make adds explicit always?
        working_repo.add(:all => true)
        begin
          working_repo.commit(commit_message)
        rescue => exception
          if exception.message =~ /nothing to commit, working \w* clean/
            return
          else
            raise Utils::Error::VersionControl.new(error_message(exception.message))
          end
        end
      end

      def commit_bare(commit_message)
        working_repo = Git.open(@working_repo_path)
        working_repo.add(:all => true)
        working_repo.commit(commit_message)
      end

      def remove_working_directory
        `git annex drop --all`
        Dir.chdir(Rails.root.to_s)
        FileUtils.rm_rf(@working_repo_path, :secure => true) if File.directory?(@working_repo_path)
      end

      def get(dir = @working_repo_path)
        _get_drop_calls(dir, 'get')
      end

      def drop(dir = @working_repo_path)
        _get_drop_calls(dir, 'drop')
      end

      def unlock(file)
        change_dir_working(@working_repo_path)
        `git annex unlock #{_sanitize(file)}`
      end

      def lock(file)
        change_dir_working(@working_repo_path)
        `git annex lock #{_sanitize(file)}`
      end

      def rolling_upgrade(dir = @working_repo_path)
        change_dir_working(dir) unless Dir.pwd == dir
        version_string = `git annex version`
        unless version_string.include?("local repository version: #{Utils.config[:supported_vca_version]}")
          `git annex upgrade` if git_annex_upgrade_supported(version_string)
        end
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
        dir = _sanitize(dir)
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

      def _sanitize(file_string)
        Shellwords.escape(file_string)
      end

      def _version_numbers(output_array, split_char, string_to_search)
        versions_line = output_array[output_array.index{|s| s.start_with?(string_to_search)}]
        versions_line.split("#{split_char}").last.lstrip.split(' ').map(&:to_i)
      end

    end
  end
end
