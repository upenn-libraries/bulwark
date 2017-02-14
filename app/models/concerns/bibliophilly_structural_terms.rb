module BibliophillyStructuralTerms
  extend ActiveSupport::Concern
  included do
    apply_schema BibliophillyStructuralSchema, ActiveFedora::SchemaIndexingStrategy.new(
        ActiveFedora::Indexers::GlobalIndexer.new([:displayable, :stored_searchable, :facetable])
    )
  end
end
