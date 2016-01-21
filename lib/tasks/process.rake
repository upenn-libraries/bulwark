namespace :process do

  desc "Trigger batch import to Fedora"
  task :import => :environment do
    Dir.glob "#{Utils.config.imports_local_staging}/#{Utils.config.repository_prefix}*.xml" do |file|
      Utils::Process.import(file)
    end
  end

  desc "Attach files to pages"
  task :attach_files_pages => :environment do
    ActiveFedora::Base.where(active_fedora_model_ssi: "Manuscript").each do |manuscript|
      Utils::Process.attach_files(manuscript.file_list, "Page", "pageImage")
    end
  end

end
