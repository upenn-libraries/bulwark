class Endpoint < ActiveRecord::Base

  belongs_to :repo, :foreign_key => 'repo_id'

  def source
    read_attribute(:source) || ''
  end

  def destination
    read_attribute(:destination) || ''
  end

  def content_type
    read_attribute(:content_type) || ''
  end

  def fetch_method
    read_attribute(:fetch_method) || ''
  end

  def protocol
    read_attribute(:protocol) || ''
  end

end
