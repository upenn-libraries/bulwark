namespace :preprocess do

  @filesystem_yml = "#{Rails.root}/config/filesystem.yml"
  fs_config = YAML.load_file(File.expand_path(@filesystem_yml, __FILE__))
  @manifests_yml = "#{Rails.root}/config/manifests.yml"
  mani_config = YAML.load_file(File.expand_path(@manifests_yml, __FILE__))
  @manifest_location = fs_config['development']['manifest_location']

  namespace :generate do

    desc "Generate checksum log"
    task :checksum_log => :environment do

      manifest_keys_array = Array.new
      manifest_values_array = Array.new
      files_array = Array.new
      manifest = Hash.new
      b = Utils::Manifests::Checksum.new("sha256")
      Dir.glob "#{fs_config['development']['assets_path']}/*" do |directory|
        Dir.glob "#{directory}/#{fs_config['development']['object_manifest_location']}" do |d|
          f = File.readlines(d)
          f.each do |line|
            lp = line.split(":")
            lp.first.strip!
            lp.last.strip!
            manifest_keys_array.push(lp.first)
            manifest_values_array.push(lp.last)
          end
          manifest = manifest_keys_array.zip(manifest_values_array).to_h

          file_list = Dir.glob("#{directory}/#{manifest["#{fs_config['development']['file_path_label']}"]}")

          b.calculate(file_list)

          hash_separated = ""
          b.checksums_hash.each do |v|
            arr = v.flatten.join("\t")
            hash_separated += arr
          end

          path = "#{directory}/#{fs_config["development"]["object_admin_path"]}/#{mani_config['development']['log_name']['checksum']}"

          m = Utils::Manifests::Manifest.new(Utils::Manifests::Checksum, path, hash_separated)

          m.save

        end
      end


    end
  end

end
