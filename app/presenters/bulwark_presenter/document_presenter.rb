module BulwarkPresenter
  class DocumentPresenter < Blacklight::DocumentPresenter

    def document_heading
      fields = Array(@configuration.view_config(:show).title_field)
      f = fields.find { |field| @document.has? field }

      if f.nil?
        render_field_value(@document.id)
      else
        render_display_field_value(@document[f])
      end
    end

    def render_document_index_label field, opts ={}
      if field.is_a? Hash
        Deprecation.warn DocumentPresenter, "Calling render_document_index_label with a hash is deprecated"
        field = field[:label]
      end
      label = case field
                when Symbol
                  @document[field]
                when Proc
                  field.call(@document, opts)
                when String
                  field
              end

      render_display_field_value label || @document.id
    end

    protected

    def render_display_field_value value=nil, field_config=nil
      safe_values = Array(value).collect { |x| x.respond_to?(:force_encoding) ? x.force_encoding("UTF-8") : x }

      if field_config and field_config.itemprop
        safe_values = safe_values.map { |x| content_tag :span, x, :itemprop => field_config.itemprop }
      end
      display_render(safe_join(safe_values, (field_config.separator if field_config) || field_value_separator))
    end

    def display_render(string)
      transformations = { ',,' => ',', '&amp;' => '&', ':,' => ':', ' ;' => ';'}
      transformations.each_pair {|d,t| string = string.gsub(d, t)}
      string.html_safe
    end

    def html_decode(string_to_decode)
      decoder = HTMLEntities.new
      return decoder.decode(string_to_decode)
    end

  end
end