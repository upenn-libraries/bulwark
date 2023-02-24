# -*- encoding : utf-8 -*-
#require 'blacklight/catalog'

class CatalogController < ApplicationController
  include Blacklight::Catalog

  before_action :home_alert, only: :index

  # These before_filters apply the hydra access controls
  #before_filter :enforce_show_permissions, :only=>:show
  # This applies appropriate access controls to all solr queries
  configure_blacklight do |config|
    # Delete document actions that we don't support
    config.index.document_actions.delete(:bookmark)

    config.show.document_actions.delete(:bookmark)
    config.show.document_actions.delete(:email)
    config.show.document_actions.delete(:sms)

    config.search_builder_class = SearchBuilder
    config.default_solr_params = {
      :qt => 'search',
      :rows => 10
    }

    # solr field configuration for search results/index views
    config.index.title_field = 'title_tesim'

    # thumbnail field
    config.index.thumbnail_method = :thumbnail

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _tsimed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar

    # Facets
    config.add_facet_field :collection_sim, label: 'Collection', limit: 5, collapse: false
    config.add_facet_field :subject_sim, label: 'Subject', limit: 5, collapse: false
    config.add_facet_field :language_sim, label: 'Language', limit: 5, collapse: false
    config.add_facet_field :date_sim, label: 'Date', limit: 5, collapse: false
    config.add_facet_field :creator_sim, label: 'Creator', limit: 5, collapse: true
    config.add_facet_field :publisher_sim, label: 'Publisher', limit: 5, collapse: true
    config.add_facet_field :item_type_sim, label: 'Type', limit: 5, collapse: true
    config.add_facet_field :personal_name_sim, label: 'Personal Name', limit: 5, collapse: true, helper_method: 'html_facet'
    config.add_facet_field :corporate_name_sim, label: 'Corporate Name', limit: 5, collapse: true,  helper_method: 'html_facet'
    config.add_facet_field :geographic_subject_sim, label: 'Geographic Subject', limit: 5, collapse: true

    config.add_facet_fields_to_solr_request!

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params[:'facet.field'] = config.facet_fields.keys
    #use this instead if you don't want to query facets marked :show=>false
    #config.default_solr_params[:'facet.field'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display

    # PQC
    config.add_index_field :title_ssim, label: 'Title', helper_method: 'html_entity'
    config.add_index_field :subject_ssim, label: 'Subject', helper_method: 'html_entity'
    config.add_index_field :description_ssim, label: 'Description', helper_method: 'html_entity'
    config.add_index_field :personal_name_ssim, label: 'Personal Name', helper_method: 'html_entity'
    config.add_index_field :corporate_name_ssim, label: 'Corporate Name', helper_method: 'html_entity'
    config.add_index_field :contributor_ssim, label: 'Contributor', helper_method: 'html_entity'
    config.add_index_field :contributing_institution_ssim, label: 'Contributing Institution', helper_method: 'html_entity'
    config.add_index_field :date_ssim, label: 'Date'
    config.add_index_field :language_ssim, label: 'Language'
    config.add_index_field :creator_ssim, label: 'Creator'
    config.add_index_field :publisher_ssim, label: 'Publisher'
    config.add_index_field :rights_ssim, label: 'Rights'
    config.add_index_field :source_ssim, label: 'Source'
    config.add_index_field :format_type_ssim, label: 'Type'

    # Catalog
    config.add_index_field :collection_ssim, label: 'Collection'
    config.add_index_field :display_call_number_ssim, label: 'Call Number' # TODO: delete when all digital objects are migrated.
    config.add_index_field :call_number_ssim, label: 'Call Number'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display

    # PQC
    config.add_show_field :title_ssim, label: 'Title', helper_method: 'html_entity'
    config.add_show_field :abstract_ssim, label: 'Abstract'
    config.add_show_field :contributor_ssim, label: 'Contributor'
    config.add_show_field :coverage_ssim, label: 'Coverage'
    config.add_show_field :creator_ssim, label: 'Creator'
    config.add_show_field :contributing_institution_ssim, label: 'Contributing Institution'
    config.add_show_field :date_ssim, label: 'Date'
    config.add_show_field :description_ssim, label: 'Description'
    config.add_show_field :format_ssim, label: 'Format'
    config.add_show_field :identifier_ssim, label: 'Identifier'
    config.add_show_field :language_ssim, label: 'Language'
    config.add_show_field :provenance_ssim, label: 'Provenance'
    config.add_show_field :publisher_ssim, label: 'Publisher'
    config.add_show_field :relation, label: 'Relation', accessor: :relation, unless: ->(_,_,d) { d.relation.blank? }
    config.add_show_field :source_ssim, label: 'Source'
    config.add_show_field :subject_ssim, label: 'Subject', :link_to_search => 'subject_sim'
    config.add_show_field :item_type_ssim, label: 'Type'
    config.add_show_field :personal_name_ssim, label: 'Personal Name'
    config.add_show_field :corporate_name_ssim, label: 'Corporate Name'
    config.add_show_field :geographic_subject_ssim, label: 'Geographic Subject'
    config.add_show_field :rights_ssim, label: 'Rights'
    config.add_show_field :notes_ssim, label: 'Notes'

    # Catalog
    config.add_show_field :display_call_number_ssim, label: 'Call Number' # TODO: remove when all digital objects are migrated.
    config.add_show_field :call_number_ssim, label: 'Call Number'

    config.add_show_field :collection_ssim, label: 'Collection'

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    config.add_search_field 'all_fields', label: 'All Fields'

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    config.add_search_field('title') do |field|
      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_local_parameters = {
        :qf => '$title_qf',
        :pf => '$title_pf'
      }
    end

    config.add_search_field('description') do |field|
      field.qt = 'search'
      field.solr_local_parameters = {
          :qf => '$description_qf',
          :pf => '$description_pf'
      }
    end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    config.add_search_field('subject') do |field|
      field.qt = 'search'
      field.solr_local_parameters = {
        :qf => '$subject_qf',
        :pf => '$subject_pf'
      }
    end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    config.add_search_field('geographic_subject') do |field|
      field.qt = 'search'
      field.solr_local_parameters = {
          :qf => '$geographic_subject_qf',
          :pf => '$geographic_subject_pf'
      }
    end

    config.add_search_field('identifier') do |field|
      field.qt = 'search'
      field.solr_local_parameters = {
          :qf => '$identifier_qf',
          :pf => '$identifier_pf'
      }
    end

    config.add_search_field('call_number') do |field|
      field.qt = 'search'
      field.solr_local_parameters = {
        :qf => '$call_number_qf',
        :pf => '$call_number_pf'
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc', label: 'relevance'
    config.add_sort_field 'system_modified_dtsi asc', label: 'least recently modified'
    config.add_sort_field 'system_modified_dtsi desc', label: 'most recently modified'
    config.add_sort_field 'id asc', label: 'ark identifier'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  def render_search_results_as_json
    docs_with_urls
    super
  end

  def docs_with_urls
    # Retrieve all thumbnail_links at the same time.
    arks = @document_list.map { |d| d['unique_identifier_tesim'].first }
    arks_to_thumbnail_links = Repo.where(unique_identifier: arks).map { |r| [r.unique_identifier, r.thumbnail_link] }.to_h

    @document_list.each do |doc|
      ark = doc['unique_identifier_tesim'].first
      thumbnail_link = arks_to_thumbnail_links[ark]
      doc._source['thumbnail_url'] = thumbnail_link if thumbnail_link
    end
  end

  def home_alert
    @home_alert = AlertMessage.home
  end
end
