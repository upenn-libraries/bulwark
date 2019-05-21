module MetadataSourceCrosswalks
  extend ActiveSupport::Concern
  class Kaplan
    def self.mapping(term_to_be_mapped)
      terms = {'type'=>'item_type',
               'abstract' => 'abstract',
               'call_number' => 'call_number',
               'collection_name' => 'collection',
               'contributor' => 'contributor',
               'corporate_name' => 'corporate_name',
               'coverage' => 'coverage',
               'creator' => 'creator',
               'date' => 'date',
               'description' => 'description',
               'format' => 'format',
               'geographic_subject' => 'geographic_subject',
               'identifier' => 'identifier',
               'collectify_identifiers' => 'identifier',
               'includes' => 'includes',
               'language' => 'language',
               'notes' => 'notes',
               'personal_name' => 'personal_name',
               'provenance' => 'provenance',
               'publisher' => 'publisher',
               'relation' => 'relation',
               'rights' => 'rights',
               'source' => 'source',
               'subject' => 'subject',
               'title' => 'title'
      }
      mapped_term = terms[term_to_be_mapped].present? ? terms[term_to_be_mapped] : nil
      return mapped_term
    end
  end
  class Pqc
    def self.mapping(term_to_be_mapped)
      terms = {'type'=>'item_type',
               'abstract' => 'abstract',
               'call_number' => 'call_number',
               'collection_name' => 'collection',
               'contributor' => 'contributor',
               'corporate_name' => 'corporate_name',
               'coverage' => 'coverage',
               'creator' => 'creator',
               'date' => 'date',
               'description' => 'description',
               'format' => 'format',
               'geographic_subject' => 'geographic_subject',
               'identifier' => 'identifier',
               'collectify_identifiers' => 'identifier',
               'includes' => 'includes',
               'language' => 'language',
               'notes' => 'notes',
               'personal_name' => 'personal_name',
               'provenance' => 'provenance',
               'publisher' => 'publisher',
               'relation' => 'relation',
               'rights' => 'rights',
               'source' => 'source',
               'subject' => 'subject',
               'title' => 'title'
      }
      mapped_term = terms[term_to_be_mapped].present? ? terms[term_to_be_mapped] : nil
      return mapped_term
    end
  end
end

