class MultipageItem < ActiveFedora::Base
  include Hydra::Works::WorkBehavior

  has_many :pages

  contains 'thumbnail'

  property :title, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/title'), multiple: true do |index|
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


  def thumbnail_link
    self.thumbnail.ldp_source.subject
  end

  def cover
    Page.where(:parent_manuscript => self.id).sort_by {|obj| obj.page_number}.first
  end

  def mint_public_identifier
    identifier = Ezid::Identifier.find(self.identifier)
    identifier.who = self.creator if self.creator.present?
    identifier.what = self.title if self.title.present?
    identifier.when = self.date if self.date.present?
    identifier.save
  end


end
