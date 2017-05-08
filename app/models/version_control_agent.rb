class VersionControlAgent < ActiveRecord::Base

  belongs_to :repo

  after_create :set_vca_attributes

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
    unless @worker.present? && @worker.repo == repo
      working_path_namespace = path_namespace
      FileUtils.mkdir_p(working_path_namespace)
      _initialize_worker(working_path_namespace)
    end
    binding.pry unless @worker.present? && @worker.repo == repo
    @worker.initialize_bare_remote
  end

  def set_remote_permissions
    unless @worker.present? && @worker.repo == repo
      working_path_namespace = path_namespace
      FileUtils.mkdir_p(working_path_namespace)
      _initialize_worker(working_path_namespace)
    end
    binding.pry unless @worker.present? && @worker.repo == repo
    @worker.set_remote_permissions
  end

  def clone(options = {})
    unless @worker.present? && @worker.repo == repo
      working_path_namespace = path_namespace
      FileUtils.mkdir_p(working_path_namespace)
      _initialize_worker(working_path_namespace)
    end
    @worker.clone(options)
  end

  def reset_hard(options = {})
    binding.pry unless @worker.present? && @worker.repo == repo
    options[:location].nil? ? @worker.reset_hard : @worker.reset_hard(options[:location])
  end

  def push_bare
    binding.pry unless @worker.present? && @worker.repo == repo
    @worker.push_bare
  end

  def push
    binding.pry unless @worker.present? && @worker.repo == repo
    @worker.push
  end

  def commit_bare(message)
    binding.pry unless @worker.present? && @worker.repo == repo
    @worker.commit_bare(message)
  end

  def add(options = {})
    binding.pry unless @worker.present? && @worker.repo == repo
    @worker.add(options)
  end

  def copy(options = {})
    binding.pry unless @worker.present? && @worker.repo == repo
    @worker.copy(options)
  end

  def commit(message)
    binding.pry unless @worker.present? && @worker.repo == repo
    @worker.commit(message)
  end

  def get(options = {})
    binding.pry unless @worker.present? && @worker.repo == repo
    options[:location].nil? ? @worker.get : @worker.get(options[:location])
  end

  def sync_content(options = {})
    binding.pry unless @worker.present? && @worker.repo == repo
    options[:directory].nil? ? @worker.sync('--content') : @worker.sync(options[:directory], '--content')
  end

  def pull(options = {})
    binding.pry unless @worker.present? && @worker.repo == repo
    options[:location].nil? ? @worker.pull : @worker.pull(options[:location])
  end

  def drop(options = {})
    binding.pry unless @worker.present? && @worker.repo == repo
    options[:drop_location].nil? ? @worker.drop : @worker.drop(options[:drop_location])
  end

  def unlock(options)
    binding.pry unless @worker.present? && @worker.repo == repo
    @worker.unlock(options)
  end

  def lock(filename = '.')
    binding.pry unless @worker.present? && @worker.repo == repo
    @worker.lock(filename)
  end

  def look_up_key( path = '')
    binding.pry unless @worker.present? && @worker.repo == repo
    @worker.look_up_key(path)
  end

  def delete_clone(options = {})
    binding.pry unless @worker.present? && @worker.repo == repo
    options[:drop_location].nil? ? @worker.drop : @worker.drop(options[:drop_location])
    @worker.remove_working_directory
  end

  private

  def _initialize_worker(path_namespace)
    @worker = "Utils::VersionControl::#{self.vc_type}".constantize.new(self.repo, path_namespace)
  end

  def path_seed
    Digest::SHA256.hexdigest("#{repo.names.git}#{SecureRandom.uuid}")
  end

  def path_namespace
    "#{Utils.config[:workspace]}/#{path_seed}"
  end

end