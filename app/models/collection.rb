class Collection < ActiveFedora::Base
  include Hydra::PCDM::CollectionBehavior
  property :title, predicate: ::RDF::Vocab::DC.title, multiple: false do |index|
    index.as :stored_searchable, :facetable
  end
  has_many :manuscript, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasMember
end
