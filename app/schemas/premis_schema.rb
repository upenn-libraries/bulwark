class PremisSchema < ActiveTriples::Schema

  property :object_identifier, predicate: ::RDF::Vocab::PREMIS.Identifier, multiple: true do |index|
    index.as :displayable
  end

  property :object_category, predicate: ::RDF::Vocab::PremisEventType.collection_PREMIS, multiple: true do |index|
    index.as :displayable
  end

  property :object_size, predicate: ::RDF::Vocab::PREMIS.ObjectCharacteristics, multiple: true do |index|
    index.as :displayable
  end

  property :original_name, predicate: ::RDF::Vocab::PREMIS.ObjectCharacteristics, multiple: true do |index|
    index.as :displayable
  end

  property :preservation_level, predicate: ::RDF::Vocab::PREMIS.PreservationLevel, multiple: true do |index|
    index.as :displayable
  end

  property :object_characteristics, predicate: ::RDF::Vocab::PREMIS.ObjectCharacteristics, multiple: true do |index|
    index.as :displayable
  end

  property :format, predicate: ::RDF::Vocab::PREMIS.Format, multiple: true do |index|
    index.as :displayable
  end

  property :format_designation, predicate: ::RDF::Vocab::PREMIS.FormatDesignation, multiple: true do |index|
    index.as :displayable
  end

  property :format_registry, predicate: ::RDF::Vocab::PREMIS.FormatRegistry, multiple: true do |index|
    index.as :displayable
  end

  property :creating_application, predicate: ::RDF::Vocab::PREMIS.CreatingApplication, multiple: true do |index|
    index.as :displayable
  end

  property :inhibitors, predicate: ::RDF::Vocab::PREMIS.Inhibitors, multiple: true do |index|
    index.as :displayable
  end

  property :event_identifier, predicate: ::RDF::Vocab::PREMIS.Event, multiple: true do |index|
    index.as :displayable
  end

  property :event_type, predicate: ::RDF::Vocab::PREMIS.Event, multiple: true do |index|
    index.as :displayable
  end

  property :event_date_time, predicate: ::RDF::Vocab::PREMIS.Event, multiple: true do |index|
    index.as :displayable
  end

  property :event_detail, predicate: ::RDF::Vocab::PREMIS.Event, multiple: true do |index|
    index.as :displayable
  end

  property :agent_identifier, predicate: ::RDF::Vocab::PREMIS.Agent, multiple: true do |index|
    index.as :displayable
  end

end
