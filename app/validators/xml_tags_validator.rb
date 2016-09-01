class XmlTagsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless record.source_type == "voyager"
      value.each do |key, mapping|
        record.errors[attribute] << I18n.t('colenda.validators.xml.starts_with_xml', :mapped_value => mapping[:mapped_value], :key => key, :xml => mapping[:mapped_value].first_three) if mapping[:mapped_value].starts_with_xml?
        record.errors[attribute] << I18n.t('colenda.validators.xml.starts_with_number', :mapped_value => mapping[:mapped_value], :key => key) if mapping[:mapped_value].starts_with_number?
        record.errors[attribute] << I18n.t('colenda.validators.xml.invalid_characters', :mapped_value => mapping[:mapped_value], :key => key) if mapping[:mapped_value].contains_xml_invalid_characters?
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

  end

end
