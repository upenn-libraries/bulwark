module PqcTerms
  extend ActiveSupport::Concern
  included do
    apply_schema PqcSchema, ActiveFedora::SchemaIndexingStrategy.new(
        ActiveFedora::Indexers::GlobalIndexer.new([:symbol, :stored_searchable, :facetable])
    )
  end
end
