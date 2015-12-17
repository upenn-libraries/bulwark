module ApplicationHelper
  def fetch_files(doc)
    model = doc['active_fedora_model_ssi']
    page = model.constantize.find(doc.id)
    file_print = page.file
    return file_print.uri.to_s.html_safe
  end
end
