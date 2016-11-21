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
