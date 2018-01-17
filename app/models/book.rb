class Book < MultiImageItem

  # required

  def init
    self.item_type ||= 'Book'
  end

end
