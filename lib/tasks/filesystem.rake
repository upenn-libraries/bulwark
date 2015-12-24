require "fileutils"

namespace :filesystem do
  @filesystem_yml = "#{Rails.root}/config/filesystem.yml"
  config = YAML.load_file(File.expand_path(@filesystem_yml, __FILE__))
  @manifest_location = config['development']['manifest_location']

  desc "Populate filesystem.yml"
  task :populate_yml => :environment do
    search_line = "#{Rails.env}:\n"
    split_on = config['development']['split_on']
    raw = File.open(@manifest_location)
    manifest_array = IO.binread(raw).split("#{split_on}")

    file_contents = File.readlines(@filesystem_yml)
    manifest_array.each do |line|
      index = file_contents.index(search_line)
      file_contents.insert(index+1, "  #{line}")
    end
    File.open(@filesystem_yml, "w+") do |new_yml|
      new_yml.puts(file_contents)
    end

    begin
      puts I18n.t('filesystem.yaml_checking')
      f = YAML.load_file(@filesystem_yml)
      puts I18n.t('filesystem.yaml_good')

    rescue Exception
      puts "#{I18n.t('filesystem.yaml_bad')}
      #{I18n.t('filesystem.yaml_label')} #{@filesystem_yml}
      #{I18n.t('filesystem.manifest_label')} #{@manifest_location}
      #{I18n.t('filesystem.yaml_separator')}
      #{$!}
      
      #{I18n.t('filesystem.yaml_separator')}
      #{I18n.t('filesystem.yaml_bad_instructions')}"

    end

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
