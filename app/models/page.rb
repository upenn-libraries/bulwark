class Page < ActiveFedora::Base
  include Hydra::PCDM::ObjectBehavior
  contains "pageImage"
  property :page_id, predicate: ::RDF::URI.new('http://library.upenn.edu/ns/pageId'), multiple: false do |index|
    index.as :stored_searchable
    index.type :stored_searchable
  end

  property :file_name, predicate: ::RDF::URI.new('http://library.upenn.edu/ns/fileName'), multiple: false do |index|
    index.as :stored_searchable
    index.type :stored_searchable
  end

  property :page_number, predicate: ::RDF::URI.new('http://library.upenn.edu/ns/pageNumber'), multiple: false do |index|
    index.as :stored_searchable
    index.type :integer
  end

  property :ocr_text, predicate: ::RDF::URI.new('http://library.upenn.edu/ns/pageText'), multiple: false do |index|
    index.as :stored_searchable
  end
  belongs_to :manuscript, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf

end
