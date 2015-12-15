class Manuscript < ActiveFedora::Base
  after_initialize :init
  include Hydra::PCDM::ObjectBehavior

  property :abstract, predicate: ::RDF::Vocab::DC.abstract, multiple: false do |index|
    index.as :stored_searchable
  end

  property :contributor, predicate: ::RDF::Vocab::DC.contributor, multiple: true do |index|
    index.as :stored_searchable
  end

  property :coverage, predicate: ::RDF::Vocab::DC.coverage, multiple: true do |index|
    index.as :stored_searchable
  end

  property :creator, predicate: ::RDF::Vocab::DC.creator, multiple: true do |index|
    index.as :stored_searchable
  end

  property :date, predicate: ::RDF::Vocab::DC.date, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :description, predicate: ::RDF::Vocab::DC.description, multiple: true do |index|
    index.as :stored_searchable
  end

  property :format, predicate: ::RDF::Vocab::DC.format, multiple: true do |index|
    index.as :stored_searchable
  end

  property :identifier, predicate: ::RDF::Vocab::DC.identifier, multiple: true do |index|
    index.as :stored_searchable
  end

  property :includes, predicate: ::RDF::Vocab::DC.hasPart, multiple: true do |index|
    index.as :stored_searchable
  end

  property :includesComponent, predicate: ::RDF::URI.new("http://www.library.upenn.edu/pqc/ns/includesComponent"), multiple: true do |index|
    index.as :stored_searchable
  end

  property :language, predicate: ::RDF::Vocab::DC.language, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :publisher, predicate: ::RDF::Vocab::DC.publisher, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :relation, predicate: ::RDF::Vocab::DC.relation, multiple: true do |index|
    index.as :stored_searchable
  end

  property :rights, predicate: ::RDF::Vocab::DC.rights, multiple: true do |index|
    index.as :displayable
  end

  property :source, predicate: ::RDF::Vocab::DC.source, multiple: true do |index|
    index.as :stored_searchable
  end

  property :subject, predicate: ::RDF::Vocab::DC.subject, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :title, predicate: ::RDF::Vocab::DC.title, multiple: false do |index|
    index.as :stored_searchable
  end

  property :item_type, predicate: ::RDF::Vocab::DC.type, multiple: false do |index|
    index.as :stored_searchable
  end

  belongs_to :collection, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
  has_many :pages, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.hasPart

  def init
    self.item_type ||= "Image"
  end

end
