module ApplicationHelper
  def fetch_files(doc)
    model = doc['active_fedora_model_ssi']
    page = model.constantize.find(doc.id)
    #binding.pry()
    file_print = page.pageImage.uri if model == "Page"
    return image_tag(file_print.to_s.html_safe) if model == "Page"
  end
end
