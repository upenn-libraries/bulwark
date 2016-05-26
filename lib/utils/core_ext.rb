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
