class CatalogSchema < ActiveTriples::Schema

  property :display_call_number, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/displayCallNumber'), multiple: true do |index|
    index.as :stored_searchable
  end

  property :normalized_call_number, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/normalizedCallNumber'), multiple: true do |index|
    index.as :stored_searchable
  end

end

