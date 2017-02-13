module PremisTerms
  extend ActiveSupport::Concern
  included do
    apply_schema PremisSchema, ActiveFedora::SchemaIndexingStrategy.new(
        ActiveFedora::Indexers::GlobalIndexer.new([:symbol, :stored_searchable, :facetable])
    )
  end
end
