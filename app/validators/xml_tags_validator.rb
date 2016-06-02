class XmlTagsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    value.each do |key, mapping|
      record.errors[:base] << "Invalid tag \"#{mapping[:mapped_value]}\" - valid XML tags cannot start with #{mapping[:mapped_value].first_three}" if mapping[:mapped_value].starts_with_xml?
      record.errors[:base] << "Invalid tag \"#{mapping[:mapped_value]}\" - valid XML tags cannot begin with numbers" if mapping[:mapped_value].starts_with_number?
      record.errors[:base] << "Invalid tag \"#{mapping[:mapped_value]}\" - valid XML tags can only contain letters, numbers, underscores, hyphens, and periods" if mapping[:mapped_value].contains_xml_invalid_characters?
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
