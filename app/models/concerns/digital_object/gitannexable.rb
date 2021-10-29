# frozen_string_literal: true
module DigitalObject
  module Gitannexable
    extend ActiveSupport::Concern

    def clone
      @clone ||= create_clone
    end

    def clone_location
      clone.dir.path
    end

    def cloned?
      @clone.present?
    end

    # Dropping annex'ed content and removing clone.
    #
    # TODO: Using `FileUtils.rm_rf` does not raise StandardErrors. We might want to
    # at least log those errors, if we don't want them raised.
    #
    # TODO: We might want to `git annex uninit` before we delete a cloned repository
    # because that way, the repository is removed from the list of repositories
    # when doing a `git annex info` and the `.git/annex` directory
    # and its contents are completely deleted.
    def delete_clone
      # Forcefully dropping content because if an error occurred we might not
      # be able to drop all the files without forcing.
      clone.annex.drop(all: true, force: true)

      parent_dir = Pathname.new(clone_location).parent
      FileUtils.rm_rf(parent_dir, secure: true) if File.directory?(parent_dir)

      @clone = nil
    end

    def remote_path
      File.join(Utils.config[:assets_path], names.git)
    end

    # Helper methods for frequently used git-annex tasks
    # Retrieving file and unlocking it. Usually needed before trying to access git-annex'ed files.
    # Should provide a relative path from the root of the cloned repository.
    def get_and_unlock(relative_path)
      version_control_agent.get({ location: relative_path }, clone_location)
      version_control_agent.unlock({ content: relative_path }, clone_location)
    end

    private

      def create_clone
        working_path_namespace = "#{Utils.config[:workspace]}/#{Digest::SHA256.hexdigest("#{names.git}#{SecureRandom.uuid}")}"
        FileUtils.mkdir_p(working_path_namespace)
        working_repo_path = "#{working_path_namespace}/#{names.git}"

        git_clone = ExtendedGit.clone(remote_path, working_repo_path)

        ignore_system_generated_files(working_repo_path)
        git_clone.annex.init(version: Utils.config[:supported_vca_version])

        special_remote = Settings.digital_object.git_annex.special_remote
        case special_remote[:type]
        when 'S3'
          ceph_config = Utils::Storage::Ceph.config
          git_clone.annex.enableremote(
            special_remote[:name],
            aws_secret_access_key: ceph_config.aws_secret_access_key,
            aws_access_key_id: ceph_config.aws_access_key_id
          )
        when 'directory'
          git_clone.annex.enableremote(special_remote[:name], directory: File.join(special_remote[:directory], unique_identifier.bucketize))
        else
          raise "Special remote type not implemented #{special_remote[:type]}"
        end

        git_clone.config('remote.origin.annex-ignore', 'true') # Does not store binary files in origin remote
        git_clone.config('annex.largefiles', 'not (include=.repoadmin/bin/*.sh)')
        git_clone.annex.fsck(from: special_remote[:name], fast: true)
        git_clone
      end

      # Ignore .nfs* files automatically generated and needed by the nfs store.
      # By using `.git/info/exclude` we can exclude the files in the
      # working directory without adding a `.gitignore` to the repo.
      def ignore_system_generated_files(dir)
        exclude_path = File.join(dir, '.git', 'info', 'exclude')
        File.open(exclude_path, 'w') { |f| f.write('.nfs*') } # Ignore `.nfs* files
      end
  end
end
