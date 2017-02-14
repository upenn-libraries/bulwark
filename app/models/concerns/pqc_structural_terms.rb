module PqcStructuralTerms
  extend ActiveSupport::Concern
  included do
    apply_schema PqcStructuralSchema, ActiveFedora::SchemaIndexingStrategy.new(
        ActiveFedora::Indexers::GlobalIndexer.new([:displayable, :stored_searchable, :facetable])
    )
  end
end
