class BibliophillySchema < ActiveTriples::Schema

  property :administrative_contact, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/administrativeContact'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :administrative_contact_email, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/administrativeContactEmail'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :metadata_creator, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/metadataCreator'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :metadata_creator_email, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/metadataCreatorEmail'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :repository_country, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/repositoryCountry'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :repository_city, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/repositoryCity'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :holding_institution, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/holdingInstitution'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :repository_name, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/repositoryName'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :source_collection, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/sourceCollection'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :call_numberid, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/callNumberid'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :record_url, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/recordUri'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :alternate_id, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/alternateId'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :alternate_id_type, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/alternateIdType'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :manuscript_name, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/manuscriptName'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :author_name, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/authorName'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :author_uri, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/authorUri'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :translator_name, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/translatorName'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :translator_uri, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/translatorUri'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :artist_name, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/artistName'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end


  property :artist_uri, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/artistUri'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :former_owner_name, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/formerOwnerName'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :former_owner_uri, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/formerOwnerUri'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :provenance, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/provenance'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :date_single, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/dateSingle'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :date_range_start, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/dateRangeStart'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :date_range_end, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/dateRangeEnd'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :date_narrative, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/dateNarrative'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :place_of_origin, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/placeOfOrigin'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :origin_details, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/originDetails'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :foliation_pagination, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/foliationPagination'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :flyleaves_and_leaves, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/flyleavesAndLeaves'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :layout, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/layout'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :colophon, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/colophon'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :collation, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/collation'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :script, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/script'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :decoration, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/decoration'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :binding, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/binding'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :watermarks, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/watermarks'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :catchwords, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/catchwords'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :signatures, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/signatures'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :notes, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/notes'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :support_material, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/supportMaterial'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :page_dimensions, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/pageDimensions'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :bound_dimensions, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/boundDimensions'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :related_resource, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/relatedResource'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :related_resource_url, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/relatedResourceUri'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :subject_names, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/subjectNames'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :subject_names_uri, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/subjectNamesUri'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :subject_topical, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/subjectTopical'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :subject_topical_uri, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/subjectTopicalUri'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :subject_geographic, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/subjectGeographic'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :subject_geographic_uri, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/subjectGeographicUri'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :subject_genre_form, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/subjectGenreForm'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

  property :subject_genre_form_uri, predicate: ::RDF::URI.new('http://library.upenn.edu/pqc/ns/subjectGenreFormUri'), multiple: true do |index|
    index.as :stored_searchable, :facetable
  end

end
