require 'git'

module Utils
  module VersionControl
    class GitAnnex

      include Filesystem

      attr_accessor :remote_repo_path, :working_repo_path

      def initialize(repo)
        @repo = repo
        @remote_repo_path = "#{Utils.config.assets_path}/#{@repo.directory}"
        @working_repo_path = "#{Utils.config.working_dir}/#{@remote_repo_path.gsub("/","_")}".gsub("__", "_")
      end

      def repo
        @repo || ''
      end

      def initialize_bare_remote
        `git init --bare #{@remote_repo_path}`
        Dir.chdir(@remote_repo_path)
        `git annex init origin`
      end

      def clone
        Git.clone(@remote_repo_path, @working_repo_path)
      end

      def reset_hard
        working_repo = Git.open(@working_repo_path)
        working_repo.reset_hard
      end

      def sync(options)
        begin
          change_dir_working
          `git annex sync #{options}`
        rescue
          puts "Trying to perform git annex sync outside of an annexed repository"
        end
      end

      def push_bare
        change_dir_working
        `git push origin master`
      end

      def push
        change_dir_working
        `git push origin master git-annex`
        `git annex sync --content`
      end

      def add
        `git annex add .`
      end

      def commit(commit_message)
        change_dir_working
        add
        working_repo = Git.open(@working_repo_path)
        working_repo.add(:all => true)
        working_repo.commit(commit_message)
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
        get_drop_calls(dir, "get")
      end

      def drop(dir = @working_repo_path)
        get_drop_calls(dir, "drop")
      end

      def unlock(file)
        change_dir_working
        `git annex unlock #{file}`
      end

      def lock(file)
        change_dir_working
        `git annex lock #{file}`
      end

      private

      def change_dir_working
        Dir.chdir(@working_repo_path) if File.directory?(@working_repo_path)
      end

      def get_drop_calls(dir, action)
        if File.directory?(dir)
          Dir.chdir(dir)
          `git annex #{action} .`
        else
          Dir.chdir(File.dirname(dir))
          `git annex #{action} #{File.basename(dir)}`
        end
      end

    end
  end
end
