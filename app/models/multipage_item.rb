class MultipageItem < ActiveFedora::Base
  include Hydra::Works::WorkBehavior

  include ::Identifiers

  around_save :manage_uuid

  has_many :pages

  contains 'thumbnail'

  property :unique_identifier, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/uniqueIdentifier'), multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :title, predicate: ::RDF::Vocab::DC.title, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :creator, predicate: ::RDF::Vocab::DC.creator, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :date, predicate: ::RDF::Vocab::DC.date, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :item_type, predicate: ::RDF::Vocab::DC.type, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :abstract, predicate: ::RDF::Vocab::DC.abstract, multiple: true do |index|
    index.as :stored_searchable
  end

  property :contributor, predicate: ::RDF::Vocab::DC.contributor, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :coverage, predicate: ::RDF::Vocab::DC.coverage, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :description, predicate: ::RDF::Vocab::DC.description, multiple: true do |index|
    index.as :stored_searchable
  end

  property :format, predicate: ::RDF::Vocab::DC.format, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :identifier, predicate: ::RDF::Vocab::DC.identifier, multiple: true do |index|
    index.as :stored_searchable
  end

  property :publisher, predicate: ::RDF::Vocab::DC.publisher, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :publisher, predicate: ::RDF::Vocab::DC.publisher, multiple: true do |index|
    index.as :stored_searchable
  end

  property :relation, predicate: ::RDF::Vocab::DC.relation, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :rights, predicate: ::RDF::Vocab::DC.rights, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :source, predicate: ::RDF::Vocab::DC.source, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :subject, predicate: ::RDF::Vocab::DC.subject, multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :includes, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/includes'), multiple: false do |index|
    index.as :stored_searchable
  end

  property :includes_component, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/includesComponent'), multiple: false do |index|
    index.as :stored_searchable
  end

  def mint_uuid
    yield
    self.mint_identifier
  end

  def format_uuid!
    self.unique_identifier = self.unique_identifier.reverse_fedorafy
  end

  def manage_uuid
    self.format_uuid! if self.unique_identifier.present? && self.unique_identifier != self.unique_identifier.reverse_fedorafy
    yield
    self.manage_identifier_metadata if self.unique_identifier.present?
  end

  def thumbnail_link
    self.thumbnail.ldp_source.subject
  end

end
