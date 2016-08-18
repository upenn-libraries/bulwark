require "rexml/document"

module RailsAdminHelper

  include CatalogHelper
  include MetadataBuilderHelper
  include MetadataSourceHelper
  include RepoHelper
  include Filesystem
  include Utils
  include MetadataSchema

  def render_git_remote_options
    render_git_directions_or_actions
  end

  def render_ingest_select_form
    render_ingest_or_message
  end

  def render_ingest_links
    render_ingested_list
  end

  def render_review_box
    repo = Repo.where("ingested = ?", [@document.id].to_yaml).first!
    render_review_status(repo)
  end

  def root_element_options
    return MetadataSchema.config[:root_element_options]
  end

  def parent_element_options
    return MetadataSchema.config[:parent_element_options]
  end

  def schema_terms
    return MetadataSchema.config[:schema_terms]
  end

  def schema_term_default(source_value)
    schema_terms = MetadataSchema.config[:schema_terms].map(&:downcase)
    if schema_terms.index(source_value).present?
      best_guess = schema_terms[schema_terms.index(source_value)]
    elsif schema_terms.index { |s| s.starts_with?(source_value.first.downcase) }.present?
      best_guess = schema_terms[schema_terms.index { |s| s.starts_with?(source_value.first.downcase) }]
    else
      best_guess = schema_terms.first
    end
    return best_guess
  end

  def attributes_display(object)
    display_hash = {}
    object.attribute_names.sort.each do |a_name|
      if object.try(a_name).present?
        items_for_display = []
        Array[object.try(a_name)].flatten(1).each do |value|
          items_for_display << value
        end
        display_hash[a_name.capitalize.to_sym] = items_for_display
      end
    end
    attributes_display = ""
    display_hash.each do |key, values|
      items = wrap_values(values)
      attributes_display << content_tag(:strong, key)
      attributes_display << content_tag(:ul, items)
    end
    return attributes_display
  end

  def wrap_values(values)
    formatted = ""
    values.each do |value|
      formatted << content_tag(:li, value.blank? ? "N/A" : value)
    end
    return formatted.html_safe
  end

  def form_label(form_type, repo_steps)
    case form_type
    when "generate_xml"
      repo_steps[:preservation_xml_generated] ? "Regenerate XML" : "Generate XML"
    when "source_select"
      repo_steps[:metadata_sources_selected] ? "Update metadata source selections" : "Select metadata sources"
    when "metadata_mappings"
      repo_steps[:metadata_mappings_generated] ? "Update metadata mappings" : "Save metadata mappings"
    when "extract_metadata"
      repo_steps[:metadata_extracted] ? "Refresh extracted metadata from sources" : "Extract metadata from sources"
    when "metadata_source_additional_info"
      repo_steps[:metadata_source_additional_info_set] ? "Update additional information" : "Save additional information"
    when "set_source_types"
      repo_steps[:metadata_source_type_specified] ? "Update source types" : "Save source types"
    when "publish_preview"
      repo_steps[:published_preview] ? "Republish preview" : "Publish preview"
    else
      "Submit"
    end
  end

end
