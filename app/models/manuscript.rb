class Manuscript < MultipageItem

  include ::BibliophillyTerms

  # required

  def init
    self.item_type ||= 'Manuscript'
  end



end
