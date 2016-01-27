require 'git'

class Repo < ActiveRecord::Base

  def create_remote
    unless Dir.exists?("/fs/pub/data/#{self.directory}")
      full_path = "/fs/pub/data/#{self.directory}"
      admin_subdirectory = "admin"
      Dir.mkdir(full_path)
      Dir.mkdir("#{full_path}/#{self.metadata_subdirectory}")
      Dir.mkdir("#{full_path}/#{self.assets_subdirectory}")
      Dir.mkdir("#{full_path}/#{admin_subdirectory}")
      populate_admin_manifest("#{full_path}/#{admin_subdirectory}")
      Git.init(full_path)
      Dir.chdir("#{full_path}")
      `git annex init`
      return {:success => "Remote successfully created"}
    else
      return {:error => "Remote already exists"}
    end

  end

  def populate_admin_manifest(full_admin_path)
    manifest_path = "#{full_admin_path}/manifest.txt"
    file_types = define_file_types
    metadata_line = "METADATA_PATH: #{self.metadata_subdirectory}/#{metadata_filename}"
    assets_line = "ASSETS_PATH: #{self.assets_subdirectory}/#{file_types}"
    File.open(manifest_path, "w+") do |file|
      file.puts("#{metadata_line}\n#{assets_line}")
    end
  end

  def define_file_types
    ft = self.file_extensions.split(",")
    ft.map! { |f| ".#{f}"}
    aft = ft.join(',')
    aft = "*{#{aft}}"
    return aft
  end

end
