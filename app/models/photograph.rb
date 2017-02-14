class Photograph < MultiImageItem

  # required

  def init
    self.item_type ||= 'Photograph'
  end



end
