module Identifiers
  extend ActiveSupport::Concern

  #TODO: Define target
  def erc_information
    {
        erc_who: self.creator.present? ? self.creator.join('; ') : MetadataSchema.config[:erc][:default_who],
        erc_what: self.title.present? ? self.title.join('; ') : '',
        erc_when: self.date.present? ? self.date.join('; ') : ''
    }
  end

  def mint_identifier
    self.unique_identifier = Ezid::Identifier.mint(erc_information).id
  end


  def manage_identifier_metadata
    Ezid::Identifier.modify(self.unique_identifier, erc_information)
  end

  def mint_container_id

  end

end

