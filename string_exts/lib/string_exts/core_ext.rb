String.class_eval do

  # Grabbing for XML checks (mostly for readability)

  def initial
    self[0]
  end

  def first_three
    self[0,3]
  end

  # XML checks

  def starts_with_xml?
    self.first_three.downcase == 'xml' ? true : false
  end

  def starts_with_number?
    true if Float(self.initial) rescue false
  end

  def contains_xml_invalid_characters?
    regex = self =~ /[^a-zA-Z0-9_.-].*$/
    regex.present? ? true : false
  end

  def valid_xml
    self.downcase.gsub(' ','_').gsub(/[^a-zA-Z0-9_.-]/, '')
  end

  # Making user-submitted strings directory-able

  def directorify
    self.gsub(' ','_')
  end

  # Bare git repos

  def gitify
    self.end_with?('.git') ? self : self.concat('.git')
  end

  # XML files

  def xmlify
    self.end_with?('.xml') ? self : self.concat('.xml')
  end

  # Manifests for file extensions

  def manifest_singular
    "*.#{self.first}"
  end

  def manifest_multiple
    "*{#{self}}"
  end

end