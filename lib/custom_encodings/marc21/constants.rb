module CustomEncodings
  module Marc21
    class Constants

      TAGS = {}

      TAGS['026'] = { 'e' => 'identifier'}
      TAGS['035'] = { 'a' => 'identifier'}
      TAGS['099'] = { 'a' => 'display_call_number'}
      TAGS['100'] = { 'a' => 'creator' }
      TAGS['110'] = { 'a' => 'corporate_name' }
      TAGS['245'] = { 'a' => 'title',
                      'b' => 'title',
                      'c' => 'title',
                      'f' => 'title',
                      'g' => 'title',
                      'h' => 'title',
                      'k' => 'title',
                      'n' => 'title',
                      'p' => 'title',
                      's' => 'title' }
      TAGS['246'] = { 'a' => 'title' }
      TAGS['260'] = { 'a' => 'publisher',
                      'b' => 'publisher',
                      'c' => 'publisher',
                      'e' => 'publisher',
                      'f' => 'publisher',
                      'g' => 'publisher' }
      TAGS['300'] = { '*' => 'format' }
      TAGS['590'] = { '*' => 'description' }
      TAGS['500'] = { '*' => 'bibliographic_note' }
      TAGS['510'] = { 'a' => 'citation_note' }
      TAGS['520'] = { '*' => 'abstract' }
      TAGS['522'] = { '*' => 'coverage' }
      TAGS['524'] = { '*' => 'preferred_citation_note' }
      TAGS['530'] = { '*' => 'additional_physical_form_note' }
      TAGS['546'] = { '*' => 'language' }
      TAGS['561'] = { 'a' => 'provenance' }
      TAGS['581'] = { '*' => 'publications_note' }
      TAGS['600'] = { 'a' => 'personal_name' }
      TAGS['650'] = { '*' => 'subject' }
      TAGS['651'] = { 'a' => 'coverage',
                      'y' => 'date',
                      'z' => 'coverage'
      }
      TAGS['655'] = { 'a' => 'subject',
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

      }
      TAGS['700'] = { 'a' => 'personal_name' }
      TAGS['773'] = { 't' => 'collection' }
      TAGS['730'] = { '*' => 'relation' }
      TAGS['740'] = { '*' => 'relation' }
      TAGS['752'] = { '*' => 'geographic_subject' }
      TAGS['856'] = { 'u' => 'relation' }

      ROLLUP_FIELDS = {}

      ROLLUP_FIELDS['260'] = {'separator' => ' '}
      ROLLUP_FIELDS['650'] = {'separator' => ' -- '}
      ROLLUP_FIELDS['752'] = {'separator' => ' -- '}

    end
  end
end

