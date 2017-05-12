class VersionControlAgent < ActiveRecord::Base

  belongs_to :repo

  after_create :set_vca_attributes

  def worker
    @worker ||= create_worker
  end

  def vc_type
    read_attribute(:vc_type) || ''
  end

  def remote_path
    read_attribute(:remote_path) || ''
  end

  def vc_type=(vc_type)
    self[:vc_type] = vc_type
  end

  def set_vca_attributes
    remote_repo_path = "#{Utils.config[:assets_path]}/#{self.repo.names.git}"
    self.remote_path = remote_repo_path
    self.save!
  end

  def init_bare
    self.worker.initialize_bare_remote
  end

  def set_remote_permissions
    self.worker.set_remote_permissions
  end

  def clone(options = {})
    create_worker
    self.worker.clone(options)
  end

  def reset_hard(location)
    self.worker.reset_hard(location)
  end

  def push_bare(location)
    self.worker.push_bare(location)
  end

  def push(location)
    self.worker.push(location)
  end

  def commit_bare(message, location)
    self.worker.commit_bare(message, location)
  end

  def add(options = {}, location)
    self.worker.add(options, location)
  end

  def copy(options = {}, location)
    self.worker.copy(options, location)
  end

  def commit(message, location)
    self.worker.commit(message, location)
  end

  def get(options = {}, location)
    self.worker.get(options, location)
  end

  def sync_content(location)
    self.worker.sync(location)
  end

  def pull(location)
    self.worker.pull(location)
  end

  def drop(options = {}, location)
    self.worker.drop(options, location)
  end

  def unlock(options, location)
    self.worker.unlock(options, location)
  end

  def lock(filename = '.', location)
    self.worker.lock(filename, location)
  end

  def look_up_key(path = '', location)
    self.worker.look_up_key(path, location)
  end

  def delete_clone(location)
    self.worker.drop(location)
    self.worker.remove_working_directory(location)
  end

  private

  def create_worker
    working_path_namespace = path_namespace
    FileUtils.mkdir_p(working_path_namespace)
    @worker = "Utils::VersionControl::#{self.vc_type}".constantize.new(self.repo, working_path_namespace)
  end

  def path_seed
    Digest::SHA256.hexdigest("#{repo.names.git}#{SecureRandom.uuid}")
  end

  def path_namespace
    "#{Utils.config[:workspace]}/#{path_seed}"
  end

end