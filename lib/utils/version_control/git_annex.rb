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

      def initialize_bare_remote
        `git init --bare #{@remote_repo_path}`
        Dir.chdir(@remote_repo_path)
        `git annex init origin`
      end

      def clone
        Git.clone(@remote_repo_path, @working_repo_path)
      end

      def sync(options = {})
        begin
          Dir.chdir(@working_repo_path) if File.directory?(@working_repo_path)
          `git annex sync #{options}`
        rescue
          puts "Trying to perform git annex sync outside of an annexed repository"
        end
      end

      def push_bare
        `git push origin master`
      end

      def push
        `git push origin master git-annex`
      end

      def commit(commit_message)
        working_repo = Git.open(@working_repo_path)
        working_repo.add(:all => true)
        working_repo.commit(commit_message)
      end

      def remove_working_directory
        Dir.chdir(Rails.root.to_s)
        FileUtils.rm_rf(@working_repo_path, :secure => true) if File.directory?(@working_repo_path)
        #TODO: Add logging
      end

      def get(dir = @working_repo_path)
        Dir.chdir(dir)
        `git annex get .`
      end

      def drop(dir = @working_repo_path)
        Dir.chdir(dir)
        `git annex drop .`
      end

    end
  end
end
