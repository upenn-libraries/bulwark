module ApplicationHelper
  def fetch_files(doc)
    model = doc['active_fedora_model_ssi']
    if model == "Manuscript"
      @image_array = Array.new
      manuscript = model.constantize.find(doc.id)
      manuscript.pages.each do |page|
        #binding.pry()
        file_print = page.pageImage.uri
        @image_array.push(file_print.to_s.html_safe)
      end
    end
    return @image_array
  end

end
