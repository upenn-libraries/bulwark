module BibliophillyTerms
  extend ActiveSupport::Concern
  included do
    apply_schema BibliophillySchema, ActiveFedora::SchemaIndexingStrategy.new(
        ActiveFedora::Indexers::GlobalIndexer.new([:symbol, :stored_searchable, :facetable])
    )
  end
end
