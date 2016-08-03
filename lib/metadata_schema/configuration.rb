module MetadataSchema
  class Configuration
    attr_accessor :root_element_options
    attr_accessor :parent_element_options
    attr_accessor :schema_terms
    attr_accessor :canonical_identifier_path
    attr_accessor :unique_identifier_field
    attr_accessor :voyager_root_element
    attr_accessor :voyager_http_lookup
    attr_accessor :voyager_multivalue_fields
  end
end
