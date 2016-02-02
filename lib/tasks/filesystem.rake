require "fileutils"
require "utils"
require "utils/configuration.rb"

namespace :filesystem do
  desc "Populate filesystem.yml"
  task :populate_yaml => :environment do
    @filesystem_yml = "#{Rails.root}/config/filesystem.yml"
    @manifest_location = Utils.config.manifest_location
    search_line = "#{Rails.env}:\n"
    split_on = Utils.config.split_on
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
end
