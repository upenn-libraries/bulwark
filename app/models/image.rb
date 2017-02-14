class Image < ActiveFedora::Base
  include Hydra::Works::FileSetBehavior

  include ::PqcStructuralTerms
  include ::BibliophillyStructuralTerms

  contains 'imageFile'

  around_save :format_container_id

  belongs_to :manuscript, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
  belongs_to :photograph, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf

  def format_container_id
    self.format_container! if self.unique_identifier.present? && self.unique_identifier != self.unique_identifier.reverse_fedorafy
    yield
  end

  def format_container!
    self.unique_identifier = self.unique_identifier.reverse_fedorafy
  end


  def serialized_attributes
    self.attribute_names.each_with_object('id' => id) { |key, hash| hash[key] = eval(self[key].inspect) }
  end

end
