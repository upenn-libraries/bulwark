class XmlTagsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if record.source_type == 'custom'
      value.each do |key, mapping|
        record.errors[attribute] << I18n.t('colenda.validators.xml_tags.starts_with_xml', :value => mapping[:mapped_value], :key => key, :xml => mapping[:mapped_value].first_three) if mapping[:mapped_value].starts_with_xml?
        record.errors[attribute] << I18n.t('colenda.validators.xml_tags.starts_with_number', :value => mapping[:mapped_value], :key => key) if mapping[:mapped_value].starts_with_number?
        record.errors[attribute] << I18n.t('colenda.validators.xml_tags.invalid_characters', :value => mapping[:mapped_value], :key => key) if mapping[:mapped_value].contains_xml_invalid_characters?
      end
    end
  end
end
