require "fileutils"

namespace :filesystem do
  @filesystem_yml = "#{Rails.root}/config/filesystem.yml"
  config = YAML.load_file(File.expand_path(@filesystem_yml, __FILE__))
  @manifest_location = config['development']['manifest_location']

  desc "Populate filesystem.yml"
  task :populate_yaml => :environment do
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
      puts I18n.t('filesystem.yaml_good') << I18n.t('filesystem.yaml_separator') << I18n.t('filesystem.yaml_good_instructions') << I18n.t('filesystem.yaml_separator')

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

  desc "Fetch flat XML"
	task :fetch_files => :environment do

    manifest_keys_array ||= []
    manifest_values_array ||= []

    Dir.glob "#{config['development']['assets_path']}/*" do |directory|
      Dir.glob "#{directory}/#{config['development']['object_manifest_location']}" do |d|
        f = File.readlines(d)

        f.each do |line|
          lp = line.split(":")
          lp.first.strip!
          lp.last.strip!
          manifest_keys_array.push(lp.first)
          manifest_values_array.push(lp.last)
        end

        manifest = manifest_keys_array.zip(manifest_values_array).to_h
        `xsltproc #{Rails.root}/lib/tasks/sv.xslt #{directory}/#{manifest["METADATA_PATH"]}`
      end
    end
	end

  desc "Attach files to Fedora metadata"
  task :attach_files => :environment do
    fs_prefix = "/fs/pub/data"
    fed_prefix = "http://localhost:8983/fedora/rest/files"
  end

  namespace :generate do
    desc "Generate sha1.log"
    task :sha1_log => :environment do
    end
  end
end
