# frozen_string_literal: true

module Bulwark
  module PennQualifiedCore
    module MarcMappings
      MULTIVALUED_FIELDS = %w[
        abstract contributor coverage creator date description identifier
        includes language publisher relation rights source
        subject title type collection personal_name corporate_name
        geographic_subject provenance notes
      ].freeze

      # Mapping of Control fields
      CONTROL_FIELDS = {
        '001' => { field: 'identifier' },
        '008' => [
          { field: 'date', chars: (7..10).to_a },
          { field: 'language', chars: (35..37).to_a }
        ]
      }.freeze

      # Mapping of MARC fields.
      MARC_FIELDS = {
        '026' => { subfields: 'e', field: 'identifier' },
        '035' => { subfields: 'a', field: 'identifier' },
        '099' => { subfields: 'a', field: 'call_number' },
        '041' => { subfields: ['a', 'h'], field: 'language' },
        '100' => { subfields: ('a'..'z').to_a, field: 'creator', join: ' ' },
        '110' => { subfields: ('a'..'z').to_a, field: 'corporate_name', join: ' ' },
        '245' => {
          subfields: ['a', 'b', 'c', 'f', 'g', 'h', 'k', 'n', 'p', 's'],
          field: 'title',
          join: ' '
        },
        '246' => { subfields: 'a', field: 'title' },
        '260' => { subfields: ['a', 'b', 'c', 'e', 'f', 'g'], field: 'publisher', join: ' ' },
        '264' => { subfields: ['a', 'b', 'c'], field: 'publisher', join: ' ' },
        '300' => { subfields: '*', field: 'format' },
        '590' => { subfields: '*', field: 'description' },
        '500' => { subfields: 'a', field: 'notes' },
        '510' => { subfields: 'a', field: 'citation_note' },
        '520' => { subfields: '*', field: 'abstract' },
        '522' => { subfields: '*', field: 'coverage' },
        '524' => { subfields: '*', field: 'preferred_citation_note' },
        '530' => { subfields: '*', field: 'additional_physical_form_note' },
        '546' => { subfields: ['a', 'b'], field: 'notes', join: ' ' },
        '561' => { subfields: 'a', field: 'provenance' },
        '581' => { subfields: '*', field: 'publications_note' },
        '600' => { subfields: 'a', field: 'personal_name' },
        '650' => { subfields: ('a'..'z').to_a, field: 'subject', join: ' -- ' },
        '651' => { subfields: ['a', 'y', 'z'], field: 'coverage', join: ' -- ' },
        '655' => { subfields: ('a'..'z').to_a, field: 'subject', join: ' -- ' },
        '700' => { subfields: ('a'..'x').to_a, field: 'personal_name', join: ' ' },
        '710' => { subfields: ('a'..'x').to_a, field: 'corporate_name', join: ' ' },
        '730' => { subfields: ('a'..'x').to_a, field: 'relation' },
        '740' => { subfields: ('a'..'x').to_a, field: 'relation' },
        '752' => { subfields: ('a'..'h').to_a, field: 'geographic_subject', join: ' -- ' },
        '773' => { subfields: 't', field: 'collection' },
        '856' => { subfields: ['u', 'z'], field: 'relation', join: ' ' }
      }.freeze
    end
  end
end
