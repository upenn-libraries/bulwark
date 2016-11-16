class VersionControlAgent < ActiveRecord::Base

  belongs_to :repo

  after_create :set_worker_attributes

  def vc_type
    read_attribute(:vc_type) || ''
  end

  def remote_path
    read_attribute(:remote_path) || ''
  end

  def vc_type=(vc_type)
    self[:vc_type] = vc_type
  end

  def set_worker_attributes
    remote_repo_path = "#{Utils.config[:assets_path]}/#{self.repo.names.git}"
    self.remote_path = remote_repo_path
    self.save!
  end

  def init_bare
    _initialize_worker
    $worker.initialize_bare_remote
  end

  def clone(options = {})
    _initialize_worker
    options[:destination].nil? ? $worker.clone : $worker.clone(options[:destination])
  end

  def reset_hard
    _initialize_worker
    $worker.reset_hard
  end

  def push_bare
    _initialize_worker
    $worker.push_bare
  end

  def push
    _initialize_worker
    $worker.push
  end

  def commit_bare(message)
    _initialize_worker
    $worker.commit_bare(message)
  end

  def add(options)
    _initialize_worker
    options[:get_location].nil? ? $worker.add : $worker.add(options[:add_location])
  end

  def commit(message)
    _initialize_worker
    $worker.commit(message)
  end

  def get(options = {})
    _initialize_worker
    options[:get_location].nil? ? $worker.get : $worker.get(options[:get_location])
  end

  def sync_content(options = {})
    _initialize_worker
    options[:directory].nil? ? $worker.sync('--content') : $worker.sync(options[:directory], '--content')
  end

  def drop(options = {})
    _initialize_worker
    options[:drop_location].nil? ? $worker.drop : $worker.drop(options[:drop_location])
  end

  def unlock(filename)
    _initialize_worker
    $worker.unlock(filename)
  end

  def lock(filename)
    _initialize_worker
    $worker.lock(filename)
  end

  def delete_clone(options = {})
    _initialize_worker
    options[:drop_location].nil? ? $worker.drop : $worker.drop(options[:drop_location])
    $worker.remove_working_directory
  end

  private

  def _initialize_worker
    $worker = "Utils::VersionControl::#{self.vc_type}".constantize.new(self.repo) unless (defined?($worker) && $worker.repo == repo)
  end

end
