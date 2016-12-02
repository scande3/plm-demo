# frozen_string_literal: true
class CatalogController < ApplicationController

  include Blacklight::Catalog
  include BlacklightMaps::ControllerOverride

  configure_blacklight do |config|
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
        qt: "search",
        rows: 20
    }

    config.view.list.default = true
    config.view.gallery.partials = [:index_header, :index]
    config.view.masonry.partials = [:index]
    config.view.slideshow.partials = [:index]

    # blacklight-maps stuff
    config.view.maps.geojson_field = 'subject_geojson_facet_ssim'
    config.view.maps.coordinates_field = 'subject_coordinates_geospatial'
    config.view.maps.placename_field = 'subject_geographic_ssim'
    config.view.maps.maxzoom = 13
    config.view.maps.show_initial_zoom = 9
    config.view.maps.facet_mode = 'geojson'

    #set default per-page
    config.default_per_page = 20

    # solr field configuration for document/show views
    config.index.title_field = "email_ssi"

    config.add_facet_field 'full_hierarchy_condition_ssim', :label => 'Full Conditions', :limit => 6, :sort => 'count', :collapse => false
    config.add_facet_field 'preferred_condition_labels_ssim', :label => 'Specific Conditions', :limit => 6, :sort => 'count', :collapse => false
    config.add_facet_field 'subject_geographic_ssim', :label => 'Location', :limit => 6, :sort => 'count', :collapse => false
    config.add_facet_field 'subject_geojson_facet_ssim', :limit => -2, :label => 'Coordinates', :show => false

    config.add_facet_fields_to_solr_request!

    config.add_index_field 'email_ssi', :label => 'User'
    config.add_index_field 'geographic_term_ssi', :label => 'Location'
    config.add_index_field 'preferred_condition_labels_ssim', :label => 'Conditions'

    config.global_search_fields = []
    config.global_search_fields << 'email_ssi^10'
    config.global_search_fields << 'preferred_condition_labels_tesim^6'
    config.global_search_fields << 'alt_condition_labels_tesim^2'
    config.global_search_fields << 'parent_hierarchy_condition_tesim'
    config.global_search_fields << 'geographic_term_ssi'
    config.global_search_fields << 'subject_geographic_tesim'

    config.add_show_field 'email_ssi', :label => 'User'
    config.add_show_field 'geographic_term_ssi', :label => 'Entered Location'
    config.add_show_field 'subject_geographic_ssim', :label => 'Parsed Location Values'
    config.add_show_field 'tgn_uri_ssi', :label => 'Location URI'
    config.add_show_field 'preferred_condition_labels_ssim', :label => 'Preferred Condition Labels'
    config.add_show_field 'alt_condition_labels_ssim', :label => 'Varient Condition Labels'
    config.add_show_field 'paired_hierarchy_condition_ssim', :label => 'Double Pipe Seperated Hierarchy'


    config.add_search_field('all_fields', label: 'All Text', include_in_advanced_search: false) do |field|
      title_name = "email_ssi"

      all_names = config.global_search_fields.join(" ")
      field.solr_parameters = {
          qf: "#{all_names}",
          pf: "#{title_name}"
      }
    end



    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, email_ssi asc', label: 'relevance'
    config.add_sort_field 'email_ssi asc', label: 'email'


    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

  end
end
