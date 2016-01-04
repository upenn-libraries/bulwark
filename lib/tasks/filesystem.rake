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
    Dir.glob "#{config['development']['assets_path']}/*" do |directory|
      Dir.glob "#{directory}/#{config['development']['object_manifest_location']}" do |d|
        f = File.readlines(d)
        g = f.first.split(":")
        g.last.strip!
        Dir.glob "#{directory}/#{g.last}" do |p|
          `xsltproc #{Rails.root}/lib/tasks/sv.xslt #{p}`
        end
      end
    end
	end

  namespace :generate do
    desc "Generate sha1.log"
    task :sha1_log => :environment do
    end
  end
end
