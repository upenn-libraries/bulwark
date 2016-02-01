namespace :process do

  desc "Trigger batch import to Fedora"
  task :import => :environment do
    Utils.import_to_fedora
  end

  desc "Attach files to pages"
  task :attach_files_pages => :environment do
    ActiveFedora::Base.where(active_fedora_model_ssi: "Manuscript").each do |manuscript|
      Utils::Process.attach_files(manuscript.file_list, "Page", "pageImage")
    end
  end

end
