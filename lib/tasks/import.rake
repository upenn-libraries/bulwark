namespace :fedora do
  @fedora_yml = "#{Rails.root}/config/fedora.yml"
  @filesystem_yml = "#{Rails.root}/config/filesystem.yml"
  fedora_config = YAML.load_file(File.expand_path(@fedora_yml, __FILE__))
  fs_config = YAML.load_file(File.expand_path(@filesystem_yml, __FILE__))
  @fedora_user = fedora_config['development']['user']
  @fedora_password = fedora_config['development']['password']

  desc "Init the database"
  task :init_env => :environment do
    k = Manuscript.create("deleteme")
    k.delete
  end

  desc "Trigger batch import to Fedora"
  task :import => :environment do
    Dir.glob "#{fs_config['development']['imports_local_staging']}/#{fs_config['development']['repository_prefix']}*.xml" do |file|
      curl_command = "curl -u #{@fedora_user}:#{@fedora_password} -X POST --data-binary @#{file} \"http://localhost:8983/fedora/rest/dev/fcr:import?format=jcr/xml\""
      `#{curl_command}`
    end

  end

  desc "Attach files to pages"
  task :attach_files => :environment do
    ActiveFedora::Base.where(active_fedora_model_ssi: "Manuscript").each do |manuscript|
      Page.where(parent_manuscript: manuscript.id).each do |p|
        file_link = ""
        fedora_link = "http://localhost:8983/fedora/rest/dev/#{p.id}/pageImage"
        manuscript.file_list.each {|f| file_link = f if f.ends_with?(p.file_name)}
        curl_command = "curl -u #{@fedora_user}:#{@fedora_password}  -X PUT -H \"Content-Type: message/external-body; access-type=URL; URL=\\\"#{file_link}\\\"\" \"#{fedora_link}\""
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
