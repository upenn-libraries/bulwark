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

  desc "Attach files to pages"
  task :attach_files => :environment do
    ActiveFedora::Base.where(active_fedora_model_ssi: "Manuscript").each do |manuscript|
      Page.where(parent_manuscript: manuscript.id).each do |p|
        file_link = ""
        fedora_link = "http://localhost:8983/fedora/rest/dev/#{p.id}/pageImage"
        manuscript.file_list.each {|f| file_link = f if f.ends_with?(p.file_name)}
        curl_command = "curl -u fedoraAdmin:fedoraAdmin  -X PUT -H \"Content-Type: message/external-body; access-type=URL; URL=\\\"#{file_link}\\\"\" \"#{fedora_link}\""
        `#{curl_command}`
        p.manuscript = manuscript
        p.save
      end
    end
  end

  namespace :solr do
    desc "Reindex Solr"
    task :reindex => :environment do
      ActiveFedora::Base.reindex_everything
    end
  end
end
