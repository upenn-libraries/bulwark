class BibliophillyStructuralSchema < ActiveTriples::Schema

  property :serial_num, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/serialNum'), multiple: true do |index|
    index.as :stored_searchable
  end

  property :display_page, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/displayPage'), multiple: true do |index|
    index.as :stored_searchable
  end

  property :tag1, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/tag1'), multiple: true do |index|
    index.as :stored_searchable
  end

  property :value1, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/value1'), multiple: true do |index|
    index.as :stored_searchable
  end

  property :tag2, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/tag2'), multiple: true do |index|
    index.as :stored_searchable
  end

  property :value2, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/value2'), multiple: true do |index|
    index.as :stored_searchable
  end

  property :tag3, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/tag3'), multiple: true do |index|
    index.as :stored_searchable
  end

  property :value3, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/value3'), multiple: true do |index|
    index.as :stored_searchable
  end

  property :tag4, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/tag4'), multiple: true do |index|
    index.as :stored_searchable
  end

  property :value4, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/value4'), multiple: true do |index|
    index.as :stored_searchable
  end

  property :tag5, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/tag5'), multiple: true do |index|
    index.as :stored_searchable
  end

  property :value5, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/value5'), multiple: true do |index|
    index.as :stored_searchable
  end

  property :tag6, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/tag6'), multiple: true do |index|
    index.as :stored_searchable
  end

  property :value6, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/value6'), multiple: true do |index|
    index.as :stored_searchable
  end

end