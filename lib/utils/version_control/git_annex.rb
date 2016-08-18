require 'git'
require 'shellwords'

module Utils
  module VersionControl
    class GitAnnex

      include Filesystem

      attr_accessor :remote_repo_path, :working_repo_path

      def initialize(repo)
        @repo = repo
        @remote_repo_path = "#{Utils.config[:assets_path]}/#{@repo.directory}"
        @working_repo_path = "#{Utils.config[:working_dir]}/#{@remote_repo_path.gsub("/","_")}".gsub("__", "_")
      end

      def repo
        @repo || ''
      end

      def initialize_bare_remote
        `git init --bare #{@remote_repo_path}`
        Dir.chdir(@remote_repo_path)
        `git annex init origin`
      end

      def clone(destination = @working_repo_path)
        begin
          Git.clone(@remote_repo_path, destination)
        rescue => exception
          raise Utils::Error::VersionControl.new(error_message(exception.message))
        end

      end

      def reset_hard
        working_repo = Git.open(@working_repo_path)
        working_repo.reset_hard
      end

      def sync(options = "")
        begin
          `git annex sync #{options}`
        rescue
          puts "Trying to perform git annex sync outside of an annexed repository"
        end
      end

      def push_bare
        _change_dir_working
        `git push origin master`
      end

      def push
        _change_dir_working
        `git push origin master git-annex`
        `git annex sync --content`
      end

      def add(dir = @working_repo_path)
        _get_drop_calls(dir, "add")
      end

      def commit(commit_message)
        _change_dir_working
        add
        working_repo = Git.open(@working_repo_path)
        working_repo.add(:all => true)
        begin
          working_repo.commit(commit_message)
        rescue => exception
          if exception.message.include?("nothing to commit, working directory clean")
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
        _get_drop_calls(dir, "get")
      end

      def drop(dir = @working_repo_path)
        _get_drop_calls(dir, "drop")
      end

      def unlock(file)
        _change_dir_working
        `git annex unlock #{_sanitize(file)}`
      end

      def lock(file)
        _change_dir_working
        `git annex lock #{_sanitize(file)}`
      end

      private

      def _change_dir_working
        Dir.chdir(@working_repo_path) if File.directory?(@working_repo_path)
      end

      def _get_drop_calls(dir, action)
        dir = _sanitize(dir)
        if File.directory?(dir)
          Dir.chdir(dir)
          `git annex #{action} .`
        else
          Dir.chdir(File.dirname(dir))
          `git annex #{action} #{File.basename(dir)}`
        end
      end

      def error_message(message)
        case(message)
        when /no changes/
          error_message = "Nothing staged for commit."
        when /does not exist/
          error_message = "Git remote does not exist.  Could not clone to perform tasks."
        when /already exists and is not an empty directory/
          error_message = "Leftover Git remote clone in working directory"
        end
        return error_message
      end

      def _sanitize(file_string)
        sanitized_file_string = Shellwords.escape(file_string)
        return sanitized_file_string
      end

    end
  end
end
