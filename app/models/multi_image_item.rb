class MultiImageItem < ColendaBase

  has_many :images

  contains 'thumbnail'

  def thumbnail_link
    self.thumbnail.ldp_source.subject
  end

end
