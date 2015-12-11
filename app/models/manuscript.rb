class Manuscript < ActiveFedora::Base
  property :title, predicate: ::RDF::Vocab::DC.title, multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :origin, predicate: ::RDF::Vocab::DC.created, multiple: false do |index|
    index.as :stored_searchable
  end

  property :description, predicate: ::RDF::Vocab::DC.description, multiple: false do |index|
    index.as :stored_searchable
  end

end
