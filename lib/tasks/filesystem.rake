require "fileutils"

namespace :filesystem do
  @filesystem_yml = "#{Rails.root}/config/filesystem.yml"
  config = YAML.load_file(File.expand_path(@filesystem_yml, __FILE__))
  @manifest_location = config['development']['manifest_location']

  desc "Populate filesystem.yml"
  task :populate_yml => :environment do
    split_on = config['development']['split_on']
    raw = File.open(@manifest_location)
    manifest_array = IO.binread(raw).split("#{split_on}")
  end

  desc "Fetc flat XML"
	task :fetch_files => :environment do
	end

  desc "Trigger batch import to Fedora"
  task :convert_to_sv => :environment do
  end

  namespace :generate do
    desc "Generate sha1.log"
    task :sha1_log => :environment do
    end
  end
end
