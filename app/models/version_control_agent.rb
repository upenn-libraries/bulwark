class VersionControlAgent < ActiveRecord::Base

  belongs_to :repo

  after_create :initialize_worker_attributes

  def vc_type=(vc_type)
    self[:vc_type] = vc_type
  end

  def initialize_worker_attributes
    initialize_worker
    self.remote_path = @@worker.remote_repo_path
    self.working_path = @@worker.working_repo_path
    self.save!
  end

  def init_bare
    initialize_worker
    @@worker.initialize_bare_remote
  end

  def clone
    binding.pry()
    initialize_worker
    @@worker.clone
    binding.pry()
  end

  def push_bare
    initialize_worker
    @@worker.push_bare
  end

  def push
    initialize_worker
    @@worker.push
  end

  def commit(message)
    initialize_worker
    @@worker.commit(message)
  end

  def get(options = {})
    initialize_worker
    options[:get_location].nil? ? @@worker.get : @@worker.get(options[:get_location])
  end

  def delete_clone(options = {})
    binding.pry()
    initialize_worker
    options[:drop_location].nil? ? @@worker.drop : @@worker.drop(options[:drop_location])
    @@worker.remove_working_directory
    binding.pry()
  end


  def initialize_worker
    @@worker = "Utils::VersionControl::#{self.vc_type}".constantize.new(self.repo) unless defined?(@@worker)
  end

end
