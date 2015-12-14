module ApplicationHelper

  def render_document_object_partials doc
    fetch_files(doc['member_ids_ssim'])
  end

  def fetch_files(page_id)
    page = ''
    page_id.each do |p|
      #page = Page.find(p)
      #render_pages(page)
    end
  end

  def render_pages(page)
    puts page.text
  end

end
