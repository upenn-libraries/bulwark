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

  def valid_xml_tag
    self.downcase.gsub(' ','_').gsub(/[^a-zA-Z0-9_.-]/, '')
  end

  def valid_xml_text
    self.gsub(/\n/,'').encode(:xml => :text)
  end

  # Sanitizing user-submitted strings as filenames

  def filename_sanitize
    self.downcase.gsub(/[^0-9A-Za-z.\-]/, '_')
  end

  # User-submitted strings as directory names

  def directorify
    self.gsub(' ','_').gsub(/[[^[:ascii:]]\/:;&\[\]|'"\(\)]/,'')
  end

  # Bare git repos

  def gitify
    self.directorify.end_with?('.git') ? self.directorify : "#{self.directorify}.git"
  end

  # Fedora names

  def fedorafy
    self.gsub('ark:/', '').gsub('/','-')
  end

  # For lookup against Repo objects

  def reverse_fedorafy
    self.start_with?('ark:/') ? self.gsub('-','/') : "ark:/#{self.gsub('-','/')}"
  end

  # S3 buckets

  def bucketize
    raise 'Could not bucketize -- string less than 3 characters long' if self.length < 3
    raise 'String must begin and end with an alphanumeric value to have a valid bucket name derived' unless (self[0] =~ /[^0-9A-Za-z]/ && self[0..63].last =~ /[^0-9A-Za-z]/).nil?
    self[0..63].downcase.gsub(/[^0-9A-Za-z\-]/, '').downcase
  end

  # XML files

  def xmlify
    self.end_with?('.xml') ? self : "#{self}.xml"
  end

  # Manifests for file extensions

  def manifest_singular
    "*.#{self}"
  end

  def manifest_multiple
    "*{#{self}}"
  end

end
