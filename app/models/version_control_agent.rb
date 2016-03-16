class VersionControlAgent < ActiveRecord::Base

  belongs_to :repo

  after_create :initialize_worker

  def vc_type=(vc_type)
    self[:vc_type] = vc_type
  end

  def initialize_worker
    @@worker = "Utils::VersionControl::#{self.vc_type}".constantize.new(self.repo)
    self.remote_path = @@worker.remote_repo_path
    self.working_path = @@worker.working_repo_path
    self.save!
  end

  def init_bare
    @@worker.initialize_bare_remote
  end

  def clone
    @@worker.clone
  end

  def push
    @@worker.push
  end

  def commit
    @@worker.commit_and_push
  end

  def get(options = {})
    options[:get_location].nil? ? @@worker.get : @@worker.get(options[:get_location])
  end

  def delete_clone(options = {})
    options[:drop_location].nil? ? @@worker.drop : @@worker.drop(options[:drop_location])
    @@worker.remove_working_directory
  end

end
