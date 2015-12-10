class Manuscript < ActiveFedora::Base
  property :title, predicate: ::RDF::DC.title, multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :origin, predicate: ::RDF::DC.created, multiple: false do |index|
    index.as :stored_searchable
  end

  property :description, predicate: ::RDF::DC.description, multiple: false do |index|
    index.as :stored_searchable
  end

end
