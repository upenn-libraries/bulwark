
namespace :fedora do

  desc "Init the database"
	task :init_env => :environment do
		k = Manuscript.create("deleteme")
		k.delete
	end

  desc "Trigger batch import to Fedora"
  task :import => :environment do
    `cd imports/ && ./import.sh`
  end

  namespace :solr do
    desc "Reindex Solr"
    task :reindex => :environment do
      ActiveFedora::Base.reindex_everything
    end
  end
end
