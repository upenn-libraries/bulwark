module Finder
  def self.fedora_find(oid)
    begin
      ActiveFedora::Base.find(oid)
    rescue
      nil
    end
  end
end
