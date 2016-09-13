class Page < ActiveFedora::Base
  include Hydra::Works::FileSetBehavior

  contains "pageImage"

  property :page_id, predicate: ::RDF::Vocab::DC.identifier, multiple: true do |index|
    index.as :stored_searchable
    index.type :stored_searchable
  end

  property :file_name, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/fileName'), multiple: false do |index|
    index.as :stored_searchable
    index.type :stored_searchable
  end

  property :page_number, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/pageNumber'), multiple: true do |index|
    index.as :stored_searchable
    index.type :integer
  end

  property :ocr_text, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/pageText'), multiple: true do |index|
    index.as :stored_searchable
  end

  property :item_type, predicate: ::RDF::Vocab::DC.type, multiple: true do |index|
    index.as :stored_searchable
  end

  property :parent_manuscript, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/parentManuscript'), multiple: true do |index|
    index.as :stored_searchable
  end

  belongs_to :manuscript, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf

  def serialized_attributes
    self.attribute_names.each_with_object("id" => id) { |key, hash| hash[key] = eval(self[key].inspect) }
  end

end
