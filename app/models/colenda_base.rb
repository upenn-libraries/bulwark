class ColendaBase < ActiveFedora::Base
  include Hydra::Works::WorkBehavior

  include ::Identifiers
  include ::PqcTerms
  include ::PremisTerms

  around_save :manage_uuid


  property :unique_identifier, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/uniqueIdentifier'), multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  def self.af_models
    %w[Manuscript Book Photograph Pamphlet Periodical]
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

end
