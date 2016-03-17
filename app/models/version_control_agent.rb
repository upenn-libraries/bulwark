class VersionControlAgent < ActiveRecord::Base

  belongs_to :repo


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
    @@worker.push_bare
    # begin
    #   @@worker.push
    # rescue
    #   @@worker.push_bare
    # end
  end

  def commit(message)
    @@worker.commit(message)
  end

  def get(options = {})
    options[:get_location].nil? ? @@worker.get : @@worker.get(options[:get_location])
  end

  def delete_clone(options = {})
    options[:drop_location].nil? ? @@worker.drop : @@worker.drop(options[:drop_location])
    @@worker.remove_working_directory
  end

end
