require 'htmlentities'

module CatalogHelper

  include Blacklight::CatalogHelperBehavior

  def render_catalog_show_preview
    render :partial => 'catalog/show_main_content_preview'
  end

  def render_document_heading(*args)
    options = args.extract_options!

    tag_or_document = args.first

    if tag_or_document.is_a? String or tag_or_document.is_a? Symbol
      Deprecation.warn(Blacklight::BlacklightHelperBehavior, "#render_document_heading with a tag argument is deprecated; pass e.g. `tag: :h4` instead")
      tag = tag_or_document
      document = @document
    else
      tag = options.fetch(:tag, :h4)
      document = tag_or_document || @document
    end

    display_title = html_decode(presenter(document).document_heading.gsub(',,',','))
    content_tag(tag, display_title, itemprop: "name")
  end

  def document_heading document=nil
    document ||= @document
    presenter(document).document_heading
  end


  def thumbnail(document, options)
    default = content_tag(:div, '', :class => 'glyphicon glyphicon-book', 'aria-hidden' => 'true').html_safe
    return default unless ActiveFedora::Base.where(:id => document.id).first.present?
    thumbnail_url = public_fedora_path("#{ActiveFedora::Base.where(:id => document.id).first.thumbnail_link}")
    Repo.where(:unique_identifier => document.id.reverse_fedorafy).pluck(:thumbnail).first ? image_tag(thumbnail_url) : default
  end

  def current_user?
    current_user != nil
  end

  def multivalue_no_separator(options={})
    options[:separator] = ' '
    html_entity(options)
  end

  def html_entity(options={})
    separator = options[:separator].nil? ? '; ' : "#{options[:separator]}"
    option_vals = []
    options[:value].each do |val|
      option_vals << html_decode(val)
    end
    return option_vals.reject(&:blank?).join(separator)
  end

  def html_facet(facet_string)
    return html_decode(facet_string)
  end

  def html_decode(string_to_decode)
    decoder = HTMLEntities.new
    return decoder.decode(string_to_decode)
  end

end
