class ReportsController < ApplicationController
  def index
    solr = RSolr.connect :url => CatalogController.blacklight_config.connection_config[:url]
    response = solr.get 'select', :params => {
        :q=>'',
        :rows=>0,
        :facet=>'on',
        'facet.field'=>'full_hierarchy_condition_ssim'
    }
    if response.present?
      @reported_conditions = Hash[*response["facet_counts"]["facet_fields"]["full_hierarchy_condition_ssim"]]
    end


    respond_to do |format|
      format.html { }
      format.rss { render :layout => false }
    end

  end
end