class Pamphlet < MultiImageItem

  # required

  def init
    self.item_type ||= 'Pamphlet'
  end

end
