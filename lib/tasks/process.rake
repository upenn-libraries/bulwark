namespace :process do
  @filesystem_yml = "#{Rails.root}/config/filesystem.yml"
  fs_config = YAML.load_file(File.expand_path(@filesystem_yml, __FILE__))

  desc "Trigger batch import to Fedora"
  task :import => :environment do
    Dir.glob "#{fs_config['development']['imports_local_staging']}/#{fs_config['development']['repository_prefix']}*.xml" do |file|
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
