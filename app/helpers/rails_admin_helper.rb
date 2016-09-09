require "rexml/document"

module RailsAdminHelper

  include CatalogHelper
  include MetadataBuilderHelper
  include MetadataSourceHelper
  include RepoHelper

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

  def get_job_status(job_id)
    ActiveJobStatus::JobStatus.get_status(job_id: job_id)
  end

  def render_template_based_on_status(process,job_id)
    render :partial => job_based_partial(process, job_id)
  end

  def root_element_options
    MetadataSchema.config[:root_element_options]
  end

  def parent_element_options
    MetadataSchema.config[:parent_element_options]
  end

  def schema_terms
    MetadataSchema.config[:schema_terms]
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
    best_guess
  end

  def render_display_attributes(view_type, attributes, image_key = "")
    attributes_display = ""
    attributes_display << content_tag(:h3, "#{view_type.capitalize} preview for #{identifier_selection(attributes)}")
    attributes_display << content_tag(:div, thumbnail_preview(image_key), :class => "thumbnail") if image_key.present?
    attributes.each do |key, value|
      items = wrap_values(value)
      attributes_display << content_tag(:strong, key)
      attributes_display << content_tag(:ul, items)
    end
    content_tag(:div, attributes_display.html_safe, :class => "fragment").html_safe
  end

  def wrap_values(value)
    content_tag(:li, value.blank? ? "N/A" : Array(value).join(", ") ).html_safe
  end

  def form_label(form_type, repo_steps)
    case form_type
    when "generate_xml"
      repo_steps[:preservation_xml_generated] ? t('colenda.rails_admin.labels.generate_xml.additional_times') : t('colenda.rails_admin.labels.generate_xml.first_time')
    when "source_select"
      repo_steps[:metadata_sources_selected] ? t('colenda.rails_admin.labels.source_select.additional_times') : t('colenda.rails_admin.labels.source_select.first_time')
    when "metadata_mappings"
      repo_steps[:metadata_mappings_generated] ? t('colenda.rails_admin.labels.metadata_mappings.additional_times') : t('colenda.rails_admin.labels.metadata_mappings.first_time')
    when "extract_metadata"
      repo_steps[:metadata_extracted] ? t('colenda.rails_admin.labels.extract_metadata.additional_times') : t('colenda.rails_admin.labels.extract_metadata.first_time')
    when "metadata_source_additional_info"
      repo_steps[:metadata_source_additional_info_set] ? t('colenda.rails_admin.labels.metadata_source_additional_info.additional_times'): t('colenda.rails_admin.labels.metadata_source_additional_info.first_time')
    when "set_source_types"
      repo_steps[:metadata_source_type_specified] ? t('colenda.rails_admin.labels.set_source_types.additional_times') : t('colenda.rails_admin.labels.set_source_types.first_time')
    when "publish_preview"
      repo_steps[:published_preview] ? t('colenda.rails_admin.labels.publish_preview.additional_times') : t('colenda.rails_admin.labels.publish_preview.first_time')
    else
      "Submit"
    end
  end

  def job_based_partial(process, job_id)
    case process
    when "ingest"
      ready_partial = "rails_admin/main/ingest_dashboard"
    when "metadata_extraction"
      ready_partial = "rails_admin/main/extract_and_map_metadata"
    when "generate_xml"
      ready_partial = "rails_admin/main/preview_xml"
    else
      ready_partial = "shared/generic_error"
    end
    (get_job_status(job_id) == :queued) || (get_job_status(job_id) == :working) ? "shared/waiting" : ready_partial
  end

  def identifier_selection(attributes)
    attributes["id"].present? ? attributes["id"] : "Object"
  end

  def thumbnail_preview(thumbnail_link)
    image_tag(thumbnail_link, :width => 100, :height => 150)
  end

end
