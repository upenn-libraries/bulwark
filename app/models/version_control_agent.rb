class VersionControlAgent < ActiveRecord::Base

  belongs_to :repo

  attr_accessor :remote_repo_path, :working_repo_path

end
