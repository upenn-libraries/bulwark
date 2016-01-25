module ApplicationHelper
  def fetch_files(doc)
    model = doc['active_fedora_model_ssi']
    if model == "Manuscript"
      @image_array = Array.new
      manuscript = model.constantize.find(doc.id)
      pages = Page.where(parent_manuscript: manuscript.id).to_a
      pages.each do |page|
        file_print = page.pageImage.uri
        @image_array.push(file_print.to_s.html_safe)
      end
    end
    return @image_array
  end
end
