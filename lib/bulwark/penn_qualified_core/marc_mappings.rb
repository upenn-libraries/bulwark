# frozen_string_literal: true

module Bulwark
  module PennQualifiedCore
    module MarcMappings
      MULTIVALUED_FIELDS = %w[
        abstract contributor coverage creator date description identifier
        includes includesComponent language publisher relation rights source
        subject title type collection personal_name corporate_name
        geographic_subject provenance
      ].freeze

      TAGS = {
        '026' => { 'e' => 'identifier' },
        '035' => { 'a' => 'identifier' },
        '099' => { 'a' => 'display_call_number' }, # TODO: Should this be `call_number`?
        '100' => { 'a' => 'creator' },
        '110' => { 'a' => 'corporate_name' },
        '245' => {
          'a' => 'title',
          'b' => 'title',
          'c' => 'title',
          'f' => 'title',
          'g' => 'title',
          'h' => 'title',
          'k' => 'title',
          'n' => 'title',
          'p' => 'title',
          's' => 'title'
        },
        '246' => { 'a' => 'title' },
        '260' => {
          'a' => 'publisher',
          'b' => 'publisher',
          'c' => 'publisher',
          'e' => 'publisher',
          'f' => 'publisher',
          'g' => 'publisher'
        },
        '300' => { '*' => 'format' },
        '590' => { '*' => 'description' },
        '500' => { '*' => 'bibliographic_note' }, # TODO: Should this be `note`?
        '510' => { 'a' => 'citation_note' },
        '520' => { '*' => 'abstract' },
        '522' => { '*' => 'coverage' },
        '524' => { '*' => 'preferred_citation_note' },
        '530' => { '*' => 'additional_physical_form_note' },
        '546' => { '*' => 'language' },
        '561' => { 'a' => 'provenance' },
        '581' => { '*' => 'publications_note' },
        '600' => { 'a' => 'personal_name' },
        '650' => { '*' => 'subject' },
        '651' => {
          'a' => 'coverage',
          'y' => 'date',
          'z' => 'coverage'
        },
        '655' => {
          'a' => 'subject',
          'b' => 'subject',
          'c' => 'subject',
          'v' => 'subject',
          'x' => 'subject',
          'y' => 'subject',
          'z' => 'subject',
          '0' => 'subject',
          '3' => 'subject',
          '5' => 'subject',
          '6' => 'subject',
          '8' => 'subject'
        },
        '700' => { 'a' => 'personal_name' },
        '773' => { 't' => 'collection' },
        '730' => { '*' => 'relation' },
        '740' => { '*' => 'relation' },
        '752' => { '*' => 'geographic_subject' },
        '856' => { 'u' => 'relation' }
      }.freeze

      ROLLUP_FIELDS = {
        '260' => { 'separator' => ' ' },
        '650' => { 'separator' => ' -- ' },
        '752' => { 'separator' => ' -- ' }
      }.freeze
    end
  end
end
