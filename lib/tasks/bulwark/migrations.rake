namespace :bulwark do
  namespace :migrations do
    desc 'Retrieving thumbnail_location from Fedora and storing it in the database'
    task add_thumbnail_location: :environment do
      Repo.find_each do |repo|
        begin
          fedora_object = ActiveFedora::Base.find(repo.names.fedora)
          if url = fedora_object.thumbnail.ldp_source.head.headers['Content-Type'].match(/url="(?<url>[^"]*)"/)[:url]
            repo.thumbnail_location = Addressable::URI.parse(url).path # Removing host and scheme
            repo.save!
          else
            puts Rainbow("Was not able to update thumbnail location for #{repo.id}. URL not found in expected location.").red
          end
        rescue => e
          puts Rainbow("Was not able to update thumbnail_location for #{repo.id}. Error: #{e.message}").red
        end
      end
    end
  end
end
