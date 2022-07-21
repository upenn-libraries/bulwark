# frozen_string_literal: true

module Bulwark
  module PennQualifiedCore
    module MarcMappings
      MULTIVALUED_FIELDS = %w[
        abstract contributor coverage creator date description identifier
        includes language publisher relation rights source
        subject title type collection personal_name corporate_name
        geographic_subject provenance
      ].freeze

      # Mapping of MARC fields.
      # Note: As of right now, there is one mapping per field. In future more mappings could be added per
      #       field by converting the hashes to an array of hashes and making the appropriate code changes.
      MARC_FIELDS = {
        '026' => { subfields: 'e', field: 'identifier' },
        '035' => { subfields: 'a', field: 'identifier' },
        '099' => { subfields: 'a', field: 'call_number' },
        '100' => { subfields: 'a', field: 'creator' },
        '110' => { subfields: 'a', field: 'corporate_name' },
        '245' => {
          subfields: ['a', 'b', 'c', 'f', 'g', 'h', 'k', 'n', 'p', 's'],
          field: 'title'
        },
        '246' => { subfields: 'a', field: 'title' },
        '260' => { subfields: ['a', 'b', 'c', 'e', 'f', 'g'], field: 'publisher', join: ' ' },
        '300' => { subfields: '*', field: 'format' },
        '590' => { subfields: '*', field: 'description' },
        '500' => { subfields: '*', field: 'bibliographic_note' }, # TODO: Should this be `note`?
        '510' => { subfields: 'a', field: 'citation_note' },
        '520' => { subfields: '*', field: 'abstract' },
        '522' => { subfields: '*', field: 'coverage' },
        '524' => { subfields: '*', field: 'preferred_citation_note' },
        '530' => { subfields: '*', field: 'additional_physical_form_note' },
        '546' => { subfields: '*', field: 'language' },
        '561' => { subfields: 'a', field: 'provenance' },
        '581' => { subfields: '*', field: 'publications_note' },
        '600' => { subfields: 'a', field: 'personal_name' },
        '650' => { subfields: '*', field: 'subject', join: ' -- ' },
        '651' => [
          { subfields: ['a', 'z'], field: 'coverage' },
          { subfields: ['y'], field: 'date' }
        ],
        '655' => {
          subfields: ['a', 'b', 'c', 'v', 'x', 'y', 'z', '0', '3', '5', '6', '8'],
          field: 'subject'
        },
        '700' => { subfields: 'a', field: 'personal_name' },
        '773' => { subfields: 't', field: 'collection' },
        '730' => { subfields: '*', field: 'relation' },
        '740' => { subfields: '*', field: 'relation' },
        '752' => { subfields: '*', field: 'geographic_subject', join: ' -- ' },
        '856' => { subfields: 'u', field: 'relation' }
      }
    end
  end
end
