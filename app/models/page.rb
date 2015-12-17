class Page < ActiveFedora::Base
  include Hydra::PCDM::ObjectBehavior
  contains "pageImage"
  property :number, predicate: ::RDF::URI.new('http://www.library.upenn.edu/hydra/pageNumber'), multiple: false do |index|
    index.as :stored_searchable
    index.type :integer
  end
  property :text, predicate: ::RDF::URI.new('http://www.library.upenn.edu/hydra/pageText'), multiple: false do |index|
    index.as :stored_searchable
  end
  belongs_to :manuscript, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf

end
