class PqcStructuralSchema < ActiveTriples::Schema

  property :unique_identifier, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/uniqueIdentifier'), multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :parent_manuscript, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/parentManuscript'), multiple: true do |index|
    index.as :stored_searchable
  end

  property :page_number, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/pageNumber'), multiple: true do |index|
    index.as :stored_searchable
  end

  property :file_name, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/fileName'), multiple: false do |index|
    index.as :stored_searchable
  end

  property :page_id, predicate: ::RDF::Vocab::DC.identifier, multiple: true do |index|
    index.as :stored_searchable
  end

  property :ocr_text, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/pageText'), multiple: true do |index|
    index.as :stored_searchable
  end

  property :item_type, predicate: ::RDF::Vocab::DC.type, multiple: true do |index|
    index.as :stored_searchable
  end

  property :page_id, predicate: ::RDF::Vocab::DC.identifier, multiple: true do |index|
    index.as :stored_searchable
  end

end