namespace :preprocess do

  namespace :generate do
    desc "Generate checksum log"
    task :checksum_log => :environment do
      preprocess = Utils::Preprocess.initialize
      files_array = Array.new
      b = Utils::Manifests::Checksum.new("sha256")
      binding.pry()
      Dir.glob "#{preprocess.assets_path}/*" do |directory|
        fs_manifest_path = "#{directory}/#{Filesystem.config.object_manifest_location}"
        checksum_path = "#{directory}/#{Filesystem.config.object_admin_path}/checksum.txt"
        if File.exist?(fs_manifest_path)
          manifest = Utils::Preprocess.get_filesystem_manifest_hash("#{fs_manifest_path}")
          file_list = Dir.glob("#{directory}/#{manifest["#{Filesystem.config.file_path_label}"]}")
          b.calculate(file_list)
          checksum_manifest = Utils::Manifests::Manifest.new(Utils::Manifests::Checksum, checksum_path, b.content)
          checksum_manifest.save
        else
          puts "WARNING: No filesystem manifest found for #{directory}, skipping...".colorize(:yellow)
        end
      end
    end
  end

end
