class Collection < ActiveFedora::Base
  include Hydra::Works::CollectionBehavior
  property :title, predicate: ::RDF::Vocab::DC.title, multiple: false do |index|
    index.as :stored_searchable, :facetable
  end
  has_many :manuscript, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasMember
end
