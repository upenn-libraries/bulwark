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

  String.class_eval do

    def starts_with_xml?
      self.first_three.downcase == "xml" ? true : false
    end

    def starts_with_number?
      true if Float(self.initial) rescue false
    end

    def contains_xml_invalid_characters?
      regex = self =~ /[^a-zA-Z0-9_.-].*$/
      regex.present? ? true : false
    end

    def initial
      self[0]
    end

    def first_three
      self[0,3]
    end

    def valid_xml
      self.downcase.gsub(' ','_').gsub(/[^a-zA-Z0-9_.-]/, '')
    end

  end

end
