class Manuscript < ActiveFedora::Base
  after_initialize :init
  include Hydra::PCDM::ObjectBehavior
  contains "pageImage"

  property :title, predicate: ::RDF::URI.new("http://library.upenn.edu/pqc/title"), multiple: true do |index|
    index.as :stored_searchable
  end
  property :creator, predicate: ::RDF::Vocab::DC.creator, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end
  property :date, predicate: ::RDF::Vocab::DC.date, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end
  property :description, predicate: ::RDF::Vocab::DC.description, multiple: true do |index|
    index.as :stored_searchable
  end
  property :item_type, predicate: ::RDF::Vocab::DC.type, multiple: false do |index|
    index.as :stored_searchable, :facetable
  end
  property :subject, predicate: ::RDF::Vocab::DC.subject, multiple: true do |index|
    index.as :stored_searchable
  end
  property :collection, predicate: ::RDF::Vocab::DC.publisher, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end
  property :identifier, predicate: ::RDF::Vocab::DC.identifier, multiple: true do |index|
    index.as :stored_searchable
  end
  property :location, predicate: ::RDF::Vocab::DC.publisher, multiple: true do |index|
    index.as :stored_searchable
  end
  property :rights, predicate: ::RDF::Vocab::DC.rights, multiple: false do |index|
    index.as :displayable
  end

  belongs_to :collection, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
  has_many :pages, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasPart

  def init
    self.item_type ||= "Manuscript"
  end

end
