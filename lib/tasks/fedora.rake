namespace :fedora do

  desc "Init the database"
  task :init_env => :environment do
    k = ActiveFedora::Base.create("deleteme")
    k.delete
  end

  namespace :solr do
    desc "Reindex Solr"
    task :reindex => :environment do
      ActiveFedora::Base.reindex_everything
    end
  end

end
