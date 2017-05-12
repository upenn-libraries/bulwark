# -*- encoding : utf-8 -*-
#require 'blacklight/catalog'

class CatalogController < ApplicationController

  include Hydra::Catalog

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
    config.add_facet_field solr_name('subject', :facetable), :label => 'Subject'
    config.add_facet_field solr_name('language', :facetable), :label => 'Language'
    config.add_facet_field solr_name('contributor', :facetable), :label => 'Contributor'
    config.add_facet_field solr_name('creator', :facetable), :label => 'Creator'
    config.add_facet_field solr_name('publisher', :facetable), :label => 'Publisher'
    config.add_facet_field solr_name('coverage', :facetable), :label => 'Coverage'
    config.add_facet_field solr_name('date', :facetable), :label => 'Date'
    config.add_facet_field solr_name('format', :facetable), :label => 'Format'
    config.add_facet_field solr_name('relation', :facetable), :label => 'Relation'
    config.add_facet_field solr_name('source', :facetable), :label => 'Source'

    # BiblioPhilly
    config.add_facet_field solr_name('holding_institution', :facetable), :label => 'Holding Institution'
    config.add_facet_field solr_name('repository_name', :facetable), :label => 'Repository Name'
    config.add_facet_field solr_name('source_collection', :facetable), :label => 'Source Collection'
    config.add_facet_field solr_name('provenance', :facetable), :label => 'Provenance'
    config.add_facet_field solr_name('date_narrative', :facetable), :label => 'Date Narrative'
    config.add_facet_field solr_name('place_of_origin', :facetable), :label => 'Place of Origin'
    config.add_facet_field solr_name('origin_details', :facetable), :label => 'Origin Details'
    config.add_facet_field solr_name('support_material', :facetable), :label => 'Support Material'
    config.add_facet_field solr_name('subject_names', :facetable), :label => 'Subject Names'
    config.add_facet_field solr_name('subject_topical', :facetable), :label => 'Subject Topical'
    config.add_facet_field solr_name('subject_geographic', :facetable), :label => 'Subject Geographic'
    config.add_facet_field solr_name('subject_genre_form', :facetable), :label => 'Subject Genre/Form'


    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params[:'facet.field'] = config.facet_fields.keys
    #use this instead if you don't want to query facets marked :show=>false
    #config.default_solr_params[:'facet.field'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display

    # PQC
    config.add_index_field solr_name('subject', :stored_searchable, type: :string), :label => 'Subject'
    config.add_index_field solr_name('description', :stored_searchable, type: :string), :label => 'Description'
    config.add_index_field solr_name('language', :stored_searchable, type: :string), :label => 'Language'
    config.add_index_field solr_name('creator', :stored_searchable, type: :string), :label => 'Creator'
    config.add_index_field solr_name('publisher', :stored_searchable, type: :string), :label => 'Publisher'
    config.add_index_field solr_name('rights', :stored_searchable, type: :string), :label => 'Rights'
    config.add_index_field solr_name('source', :stored_searchable, type: :string), :label => 'Source'

    config.add_index_field solr_name('display_call_number', :stored_searchable, type: :string), :label => 'Call Number'

    # BiblioPhilly
    config.add_index_field solr_name('manuscript_name', :stored_searchable, type: :string), :label => 'Manuscript Name'
    config.add_index_field solr_name('administrative_contact', :stored_searchable, type: :string), :label => 'Administrative Contact'
    config.add_index_field solr_name('metadata_creator', :stored_searchable, type: :string), :label => 'Metadata Creator'
    config.add_index_field solr_name('holding_institution', :stored_searchable, type: :string), :label => 'Holding Institution'
    config.add_index_field solr_name('repository_name', :stored_searchable, type: :string), :label => 'Repository Name'
    config.add_index_field solr_name('source_collection', :stored_searchable, type: :string), :label => 'Source Collection'
    config.add_index_field solr_name('call_number_id', :stored_searchable, type: :string), :label => 'Call Number ID'
    config.add_index_field solr_name('record_url', :stored_searchable, type: :string), :label => 'Record URL'
    config.add_index_field solr_name('alternate_id', :stored_searchable, type: :string), :label => 'Alternate ID'
    config.add_index_field solr_name('alternate_id_type', :stored_searchable, type: :string), :label => 'Alternate ID Type'
    config.add_index_field solr_name('date_single', :stored_searchable, type: :string), :label => 'Date Single'
    config.add_index_field solr_name('date_range_start', :stored_searchable, type: :string), :label => 'Date Range Start'
    config.add_index_field solr_name('date_range_end', :stored_searchable, type: :string), :label => 'Date Range End'
    config.add_index_field solr_name('date_narrative', :stored_searchable, type: :string), :label => 'Date Narrative'
    config.add_index_field solr_name('place_of_origin', :stored_searchable, type: :string), :label => 'Place of Origin'
    config.add_index_field solr_name('origin_details', :stored_searchable, type: :string), :label => 'Origin Details'
    config.add_index_field solr_name('notes', :stored_searchable, type: :string), :label => 'Notes'
    config.add_index_field solr_name('support_material', :stored_searchable, type: :string), :label => 'Support Material'
    config.add_index_field solr_name('page_dimensions', :stored_searchable, type: :string), :label => 'Page Dimensions'
    config.add_index_field solr_name('bound_dimensions', :stored_searchable, type: :string), :label => 'Bound Dimensions'
    config.add_index_field solr_name('subject_names', :stored_searchable, type: :string), :label => 'Subject Names'
    config.add_index_field solr_name('subject_topical', :stored_searchable, type: :string), :label => 'Subject Topical'
    config.add_index_field solr_name('subject_geographic', :stored_searchable, type: :string), :label => 'Subject Geographic'
    config.add_index_field solr_name('subject_genre_form', :stored_searchable, type: :string), :label => 'Subject Genre/Form'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display

    # PQC
    config.add_show_field solr_name('abstract', :stored_searchable, type: :string), :label => 'Abstract'
    config.add_show_field solr_name('contributor', :stored_searchable, type: :string), :label => 'Contributor'
    config.add_show_field solr_name('coverage', :stored_searchable, type: :string), :label => 'Coverage'
    config.add_show_field solr_name('creator', :stored_searchable, type: :string), :label => 'Creator'
    config.add_show_field solr_name('description', :stored_searchable, type: :string), :label => 'Description'
    config.add_show_field solr_name('date', :stored_searchable, type: :string), :label => 'Date'
    config.add_show_field solr_name('format', :stored_searchable, type: :string), :label => 'Format'
    config.add_show_field solr_name('identifier', :stored_searchable, type: :string), :label => 'Identifier'
    config.add_show_field solr_name('language', :stored_searchable, type: :string), :label => 'Language'
    config.add_show_field solr_name('publisher', :stored_searchable, type: :string), :label => 'Publisher'
    config.add_show_field solr_name('relation', :stored_searchable, type: :string), :label => 'Relation'
    config.add_show_field solr_name('rights', :stored_searchable, type: :string), :label => 'Rights'
    config.add_show_field solr_name('source', :stored_searchable, type: :string), :label => 'Source'
    config.add_show_field solr_name('subject', :stored_searchable, type: :string), :label => 'Subject'
    config.add_show_field solr_name('title', :stored_searchable, type: :string), :label => 'Title'

    # Catalog
    config.add_show_field solr_name('display_call_number', :stored_searchable, type: :string), :label => 'Call Number'


    # BiblioPhilly
    config.add_show_field solr_name('administrative_contact', :stored_searchable, type: :string), :label => 'Administrative Contact'
    config.add_show_field solr_name('administrative_contact_email', :stored_searchable, type: :string), :label => 'Administrative Contact Email'
    config.add_show_field solr_name('metadata_creator', :stored_searchable, type: :string), :label => 'Metadata Creator'
    config.add_show_field solr_name('metadata_creator_email', :stored_searchable, type: :string), :label => 'Metadata Creator Email'
    config.add_show_field solr_name('repository_country', :stored_searchable, type: :string), :label => 'Repository Country'
    config.add_show_field solr_name('repository_city', :stored_searchable, type: :string), :label => 'Repository City'
    config.add_show_field solr_name('holding_institution', :stored_searchable, type: :string), :label => 'Holding Institution'
    config.add_show_field solr_name('repository_name', :stored_searchable, type: :string), :label => 'Repository Name'
    config.add_show_field solr_name('source_collection', :stored_searchable, type: :string), :label => 'Source Collection'
    config.add_show_field solr_name('call_number_id', :stored_searchable, type: :string), :label => 'Call Number ID'
    config.add_show_field solr_name('record_url', :stored_searchable, type: :string), :label => 'Record URL'
    config.add_show_field solr_name('alternate_id', :stored_searchable, type: :string), :label => 'Alternate ID'
    config.add_show_field solr_name('alternate_id_type', :stored_searchable, type: :string), :label => 'Alternate ID Type'
    config.add_show_field solr_name('manuscript_name', :stored_searchable, type: :string), :label => 'Manuscript Name'
    config.add_show_field solr_name('author_name', :stored_searchable, type: :string), :label => 'Author Name'
    config.add_show_field solr_name('author_uri', :stored_searchable, type: :string), :label => 'Author URI'
    config.add_show_field solr_name('translator_name', :stored_searchable, type: :string), :label => 'Translator Name'
    config.add_show_field solr_name('translator_uri', :stored_searchable, type: :string), :label => 'Translator URI'
    config.add_show_field solr_name('artist_name', :stored_searchable, type: :string), :label => 'Artist Name'
    config.add_show_field solr_name('artist_uri', :stored_searchable, type: :string), :label => 'Artist URI'
    config.add_show_field solr_name('former_owner_name', :stored_searchable, type: :string), :label => 'Former Owner Name'
    config.add_show_field solr_name('former_owner_uri', :stored_searchable, type: :string), :label => 'Former Owner URI'
    config.add_show_field solr_name('provenance', :stored_searchable, type: :string), :label => 'Provenance'
    config.add_show_field solr_name('date_single', :stored_searchable, type: :string), :label => 'Date Single'
    config.add_show_field solr_name('date_range_start', :stored_searchable, type: :string), :label => 'Date Range Start'
    config.add_show_field solr_name('date_range_end', :stored_searchable, type: :string), :label => 'Date Range End'
    config.add_show_field solr_name('date_narrative', :stored_searchable, type: :string), :label => 'Date Narrative'
    config.add_show_field solr_name('place_of_origin', :stored_searchable, type: :string), :label => 'Place of Origin'
    config.add_show_field solr_name('origin_details', :stored_searchable, type: :string), :label => 'Origin Details'
    config.add_show_field solr_name('foliation_pagination', :stored_searchable, type: :string), :label => 'Foliation/Pagination'
    config.add_show_field solr_name('flyleaves_and_leaves', :stored_searchable, type: :string), :label => 'Flyleaves &amp; Leaves'
    config.add_show_field solr_name('layout', :stored_searchable, type: :string), :label => 'Layout'
    config.add_show_field solr_name('colophon', :stored_searchable, type: :string), :label => 'Colophon'
    config.add_show_field solr_name('collation', :stored_searchable, type: :string), :label => 'Collation'
    config.add_show_field solr_name('script', :stored_searchable, type: :string), :label => 'Script'
    config.add_show_field solr_name('decoration', :stored_searchable, type: :string), :label => 'Decoration'
    config.add_show_field solr_name('binding', :stored_searchable, type: :string), :label => 'Binding'
    config.add_show_field solr_name('watermarks', :stored_searchable, type: :string), :label => 'Watermarks'
    config.add_show_field solr_name('catchwords', :stored_searchable, type: :string), :label => 'Catchwords'
    config.add_show_field solr_name('signatures', :stored_searchable, type: :string), :label => 'Signatures'
    config.add_show_field solr_name('notes', :stored_searchable, type: :string), :label => 'Notes'
    config.add_show_field solr_name('support_material', :stored_searchable, type: :string), :label => 'Support Material'
    config.add_show_field solr_name('page_dimensions', :stored_searchable, type: :string), :label => 'Page Dimensions'
    config.add_show_field solr_name('bound_dimensions', :stored_searchable, type: :string), :label => 'Bound Dimensions'
    config.add_show_field solr_name('related_resource', :stored_searchable, type: :string), :label => 'Related Resource'
    config.add_show_field solr_name('related_resource_url', :stored_searchable, type: :string), :label => 'Related Resource URL'
    config.add_show_field solr_name('subject_names', :stored_searchable, type: :string), :label => 'Subject Names'
    config.add_show_field solr_name('subject_names_uri', :stored_searchable, type: :string), :label => 'Subject Names URI'
    config.add_show_field solr_name('subject_topical', :stored_searchable, type: :string), :label => 'Subject Topical'
    config.add_show_field solr_name('subject_topical_uri', :stored_searchable, type: :string), :label => 'Subject Topical URI'
    config.add_show_field solr_name('subject_geographic', :stored_searchable, type: :string), :label => 'Subject Geographic'
    config.add_show_field solr_name('subject_geographic_uri', :stored_searchable, type: :string), :label => 'Subject Geographic URI'
    config.add_show_field solr_name('subject_genre_form', :stored_searchable, type: :string), :label => 'Subject Genre/Form'
    config.add_show_field solr_name('subject_genre_form_uri', :stored_searchable, type: :string), :label => 'Subject Genre/Form URI'
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

    config.add_search_field('author') do |field|
      field.solr_local_parameters = {
        :qf => '$author_qf',
        :pf => '$author_pf'
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
