namespace :bulwark do
  namespace :repo do
    desc 'Purges Repo. Removes db object, git repository and special remotes.'
    task purge: :environment do
      abort(Rainbow('Incorrect arguments. Pass arklist=/path/to/file or arks=seperated,by,commas').red) if ENV['arklist'].blank? && ENV['arks'].blank?

      # Pass in ARK(s) for digital object(s) to be deleted.
      arks = open(ENV['arklist']).map(&:strip!) if ENV['arklist'].present?
      arks = ENV['arks'].split(',')             if ENV['arks'].present?

      puts Rainbow("Preparing to purge #{arks.size} repo(s)...\n").yellow

      arks.each do |ark|
        repo = Repo.find_by(unique_identifier: ark)

        if repo.nil?
          puts Rainbow("Could not find a Repo with the unique identifier: #{ark}\n").red
          next
        end

        puts Rainbow("Deleting #{ark}...").green

        # Remove git repository.
        remote_path = repo.version_control_agent.remote_path
        begin
          FileUtils.remove_dir(remote_path)
          puts "  Git Repository: Removed"
        rescue StandardError => e
          puts Rainbow("  Git Repository: Error removing git repository from #{remote_path}").red
        end

        # Remove Ceph (S3) bucket.
        ceph = Aws::S3::Resource.new(
          access_key_id: ENV["AWS_ACCESS_KEY_ID"],
          secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
          endpoint: ENV["STORAGE_PROTOCOL"] + ENV["STORAGE_HOST"],
          force_path_style: true,
          region: 'us-east-1' # Default
        )

        if ceph.bucket(repo.names.bucket).exists?
          begin
            ceph.bucket(repo.names.bucket).delete! # Deletes bucket and all of its contents
            puts "  Ceph Bucket: Deleted"
          rescue
            puts Rainbow("  Ceph Bucket: Error deleting bucket").red
          end
        else
          puts "  Ceph Bucket: Does not exist"
        end

        # Purposefully not deleting fedora object and solr documents because they will
        # most likely be recreated.

        # Checks for Fedora object
        begin
          ActiveFedora::Base.find(repo.names.fedora)
          puts Rainbow("  Fedora Object: Found for id #{repo.names.fedora}").red
        rescue ActiveFedora::ObjectNotFoundError
          puts "  Fedora Object: Not found"
        end

        # Checks for Solr document,
        if Blacklight.default_index.search(q:"id:#{repo.names.fedora}", fl: 'id').docs.count == 1
          puts Rainbow("  Solr Object: Found for id #{repo.names.fedora}").red
        else
          puts "  Solr Object: Not Found"
        end

        # Remove DB object
        success = repo.destroy
        puts "  Database Record: #{success ? 'Removed' : "Error deleting id=#{repo.id}"}\n"
      end

    end
  end
end
