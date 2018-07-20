# -*- encoding : utf-8 -*-
#require 'blacklight/catalog'

class CatalogController < ApplicationController

  include Hydra::Catalog

  def default_url_options
    { :protocol => ENV['CATALOG_CONTROLLER_PROTOCOL'] }
  end

  # These before_filters apply the hydra access controls
  #before_filter :enforce_show_permissions, :only=>:show
  # This applies appropriate access controls to all solr queries

  add_nav_action 'admin_repo/admin_menu', if: :current_user?

  CatalogController.search_params_logic += [:exclude_unwanted_models]#, :exclude_unwanted_terms]

  configure_blacklight do |config|
    config.search_builder_class = Hydra::SearchBuilder
    config.default_solr_params = {
      :qt => 'search',
      :rows => 10
    }

    # solr field configuration for search results/index views
    config.index.title_field = 'title_tesim'
    config.index.display_type_field = 'has_model_ssim'

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

    # PQC
    config.add_facet_field solr_name('subject', :facetable), :label => 'Subject', :limit => 5, :collapse => false
    config.add_facet_field solr_name('language', :facetable), :label => 'Language', :limit => 5, :collapse => false
    config.add_facet_field solr_name('date', :facetable), :label => 'Date', :limit => 5, :collapse => false
    config.add_facet_field solr_name('contributor', :facetable), :label => 'Contributor', :limit => 5, :collapse => true
    config.add_facet_field solr_name('creator', :facetable), :label => 'Creator', :limit => 5, :collapse => true
    config.add_facet_field solr_name('publisher', :facetable), :label => 'Publisher', :limit => 5, :collapse => true
    config.add_facet_field solr_name('coverage', :facetable), :label => 'Coverage', :limit => 5, :collapse => true
    config.add_facet_field solr_name('format', :facetable), :label => 'Format', :limit => 5, :collapse => true
    config.add_facet_field solr_name('item_type', :facetable), :label => 'Type', :limit => 5, :collapse => true
    config.add_facet_field solr_name('relation', :facetable), :label => 'Relation', :limit => 5, :collapse => true
    config.add_facet_field solr_name('source', :facetable), :label => 'Source', :limit => 5, :collapse => true
    config.add_facet_field solr_name('personal_name', :facetable), :label => 'Personal Name', :limit => 5, :collapse => true, helper_method: 'html_facet'
    config.add_facet_field solr_name('corporate_name', :facetable), :label => 'Corporate Name',:limit => 5, :collapse => true,  helper_method: 'html_facet'
    config.add_facet_field solr_name('geographic_subject', :facetable), :label => 'Geographic Subject', :limit => 5, :collapse => true

    # Catalog
    config.add_facet_field solr_name('collection', :facetable), :label => 'Collection', :limit => 5, :collapse => true

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
    config.add_index_field solr_name('title', :stored_searchable, type: :string), :label => 'Title', helper_method: 'multivalue_no_separator'
    config.add_index_field solr_name('subject', :stored_searchable, type: :string), :label => 'Subject', helper_method: 'html_entity'
    config.add_index_field solr_name('description', :stored_searchable, type: :string), :label => 'Description', helper_method: 'html_entity'
    config.add_index_field solr_name('personal_name', :stored_searchable, type: :string), :label => 'Personal Name', helper_method: 'html_entity'
    config.add_index_field solr_name('corporate_name', :stored_searchable, type: :string), :label => 'Corporate Name', helper_method: 'html_entity'
    config.add_index_field solr_name('date', :stored_searchable, type: :string), :label => 'Date'
    config.add_index_field solr_name('language', :stored_searchable, type: :string), :label => 'Language'
    config.add_index_field solr_name('creator', :stored_searchable, type: :string), :label => 'Creator'
    config.add_index_field solr_name('publisher', :stored_searchable, type: :string), :label => 'Publisher'
    config.add_index_field solr_name('rights', :stored_searchable, type: :string), :label => 'Rights'
    config.add_index_field solr_name('source', :stored_searchable, type: :string), :label => 'Source'
    config.add_index_field solr_name('format_type', :stored_searchable, type: :string), :label => 'Type'

    # Catalog
    config.add_index_field solr_name('collection', :stored_searchable), :label => 'Collection'
    config.add_index_field solr_name('display_call_number', :stored_searchable, type: :string), :label => 'Call Number'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display

    # PQC
    config.add_show_field solr_name('title', :stored_searchable, type: :string), :label => 'Title', helper_method: 'multivalue_no_separator'
    config.add_show_field solr_name('abstract', :stored_searchable, type: :string), :label => 'Abstract'
    config.add_show_field solr_name('contributor', :stored_searchable, type: :string), :label => 'Contributor'
    config.add_show_field solr_name('coverage', :stored_searchable, type: :string), :label => 'Coverage'
    config.add_show_field solr_name('creator', :stored_searchable, type: :string), :label => 'Creator'
    config.add_show_field solr_name('date', :stored_searchable, type: :string), :label => 'Date'
    config.add_show_field solr_name('description', :stored_searchable, type: :string), :label => 'Description'
    config.add_show_field solr_name('format', :stored_searchable, type: :string), :label => 'Format'
    config.add_show_field solr_name('identifier', :stored_searchable, type: :string), :label => 'Identifier'
    config.add_show_field solr_name('language', :stored_searchable, type: :string), :label => 'Language'
    config.add_show_field solr_name('provenance', :stored_searchable, type: :string), :label => 'Provenance'
    config.add_show_field solr_name('publisher', :stored_searchable, type: :string), :label => 'Publisher'
    config.add_show_field solr_name('relation', :stored_searchable, type: :string), :label => 'Relation'
    config.add_show_field solr_name('source', :stored_searchable, type: :string), :label => 'Source'
    config.add_show_field solr_name('subject', :stored_searchable, type: :string), :label => 'Subject', :link_to_search => 'subject_sim'
    config.add_show_field solr_name('item_type', :stored_searchable, type: :string), :label => 'Type'
    config.add_show_field solr_name('personal_name', :stored_searchable, type: :string), :label => 'Personal Name'
    config.add_show_field solr_name('corporate_name', :stored_searchable, type: :string), :label => 'Corporate Name'
    config.add_show_field solr_name('geographic_subject', :stored_searchable, type: :string), :label => 'Geographic Subject'
    config.add_show_field solr_name('rights', :stored_searchable, type: :string), :label => 'Rights'
    
    # Catalog
    config.add_show_field solr_name('display_call_number', :stored_searchable, type: :string), :label => 'Call Number'
    config.add_show_field solr_name('collection', :stored_searchable, type: :string), :label => 'Collection'

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

    config.add_search_field 'all_fields', :label => 'All Fields'

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

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, pub_date_dtsi desc, title_tesi asc', :label => 'relevance'
    config.add_sort_field 'pub_date_dtsi desc, title_tesi asc', :label => 'year'
    config.add_sort_field 'author_tesi asc, title_tesi asc', :label => 'author'
    config.add_sort_field 'title_tesi asc, pub_date_dtsi desc', :label => 'title'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

  end

  def exclude_unwanted_models(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    unwanted_models.each do |um|
    if um.kind_of?(String)
      model_uri = um
    else
      model_uri = um.to_class_uri
      end
    solr_parameters[:fq] << "-has_model_ssim:\"#{model_uri}\""
    end
  end

  def exclude_unwanted_terms(solr_parameters, user_parameters)
    solr_parameters[:fq] << "-title_tesim:\"Book of\""
  end

  def unwanted_models
    [Collection, Image, ActiveFedora::DirectContainer, ActiveFedora::IndirectContainer, ActiveFedora::Aggregation::Proxy]
  end

end
