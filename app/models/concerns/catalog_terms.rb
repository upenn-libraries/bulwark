module CatalogTerms
  extend ActiveSupport::Concern
  included do
    apply_schema CatalogSchema, ActiveFedora::SchemaIndexingStrategy.new(
        ActiveFedora::Indexers::GlobalIndexer.new([:stored_searchable])
    )
  end
end
