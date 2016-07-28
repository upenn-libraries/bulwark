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
    return MetadataSchema.config.root_element_options
  end

  def parent_element_options
    return MetadataSchema.config.parent_element_options
  end

  def schema_terms
    return MetadataSchema.config.schema_terms
  end

  def schema_term_default(source_value)
    schema_terms = MetadataSchema.config.schema_terms.map(&:downcase)
    if schema_terms.index(source_value).present?
      best_guess = schema_terms[schema_terms.index(source_value)]
    elsif schema_terms.index { |s| s.starts_with?(source_value.first.downcase) }.present?
      best_guess = schema_terms[schema_terms.index { |s| s.starts_with?(source_value.first.downcase) }]
    else
      best_guess = schema_terms.first
    end
    return best_guess
  end

  def form_label(form_type, repo_steps)
    case form_type
    when "generate_xml"
      #binding.pry()
      "Generate XML"
    else
      "Submit"
    end
  end

end
