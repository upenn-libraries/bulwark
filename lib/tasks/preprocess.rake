namespace :preprocess do

  namespace :generate do
    desc "Generate checksum log"
    task :checksum_log => :environment do
      b = Utils::Manifests::Checksum.new("sha256")
      Dir.glob "#{Utils.config.assets_path}/*" do |directory|
        manifest_present = Utils::Preprocess.check_for_manifest("#{directory}/#{Utils.config.object_manifest_location}")
        if(manifest_present)
          manifest, file_list = Utils::Preprocess.build_for_preprocessing(directory)
          checksum_path = "#{directory}/#{Utils.config.object_admin_path}/checksum.tsv"
          b.calculate(file_list)
          checksum_manifest = Utils::Manifests::Manifest.new(Utils::Manifests::Checksum, checksum_path, b.content)
          checksum_manifest.save
        end
      end
    end
  end

end
