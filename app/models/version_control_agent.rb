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
    remote_repo_path = File.join(Settings.digital_object.remotes_path, self.repo.names.git)
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

  def push(options = {}, location)
    self.worker.push(options, location)
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
      @worker = "Utils::VersionControl::#{self.vc_type}".constantize.new(self.repo)
    end
end
