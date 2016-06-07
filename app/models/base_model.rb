class BaseModel < ActiveFedora::Base

  property :review_status, predicate: ::RDF::URI.new("http://library.upenn.edu/pqc/ns/reviewStatus"), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

end
