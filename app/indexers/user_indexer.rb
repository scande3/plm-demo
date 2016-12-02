
class UserIndexer

  def to_solr(user)
    @user = user
    solr = RSolr.connect :url => CatalogController.blacklight_config.connection_config[:url]
    doc = set_id

    User.columns_hash.each do |key, type|
      if self.respond_to?(key)
        doc.merge!(self.send(key.to_sym)) if user.send(key.to_sym).present?
      else
        doc.merge!(self.default_field(key, type)) unless user.send(key.to_sym).blank? || key.include?('password') #Don't put password hashes in solr
      end
    end

    #TODO: Relationships should be dynamically detected and resolved on indexers for those objects.
    doc = condition_terms(doc)

    solr.add [doc.symbolize_keys], :add_attributes => {:commitWithin => 10}
  end

  def condition_terms(doc)
    return_hash = doc
    return_hash['preferred_condition_labels_ssim'] = []
    return_hash['alt_condition_labels_ssim'] = []
    return_hash['parent_hierarchy_condition_ssim'] = []
    return_hash['full_hierarchy_condition_ssim'] = []
    return_hash['paired_hierarchy_condition_ssim'] = []
    return_hash['condition_uri_ssim'] = []

    @user.condition_terms.each do |condition_obj|
      return_hash['condition_uri_ssim'] << condition_obj.concept_uri

      #FIXME: Cheating by just using the setup from Mei at the moment...
      concept_term_graph = ::Mei::Mesh.pop_graph(condition_obj.concept_uri)
      return_hash['preferred_condition_labels_ssim'] << concept_term_graph.query(:subject=>::RDF::URI.new(condition_obj.concept_uri), :predicate=>::Mei::Mesh::rdfs_namepace('label')).first.object.value


      # Alternative labels - copied from Mei::Mesh - should refactor to one place
      repo = ::Mei::Mesh.pop_graph(condition_obj.concept_uri)
      repo.query(:subject=>::RDF::URI.new(condition_obj.concept_uri), :predicate=>Mei::Mesh.nlm_namepace('preferredConcept')).each_statement do |result_statement|
        if !result_statement.object.literal? and result_statement.object.uri?
          concept_uri = result_statement.object.to_s

          concept_repo = ::Mei::Mesh.pop_graph(concept_uri)
          concept_repo.query(:subject=>::RDF::URI.new(concept_uri), :predicate=>Mei::Mesh.nlm_namepace('term')).each_statement do |concept_statement|
            term_uri = concept_statement.object.to_s
            term_repo = ::Mei::Mesh.pop_graph(term_uri)
            term_repo.query(:subject=>::RDF::URI.new(term_uri), :predicate=>Mei::Mesh.nlm_namepace('prefLabel')).each_statement do |term_statement|
              return_hash['alt_condition_labels_ssim'] << term_statement.object.to_s
            end
          end
        end

      end

      # Hierarchy
      hierarchy_array = get_recursive_condition_level(condition_obj.concept_uri)
      return_hash['parent_hierarchy_condition_ssim'] += hierarchy_array

      hierarchy_array << return_hash['preferred_condition_labels_ssim'].last
      hierarchy_array.reverse!
      return_hash['paired_hierarchy_condition_ssim'] << hierarchy_array.join('||')
    end

    # Remove duplicate strings
    return_hash['parent_hierarchy_condition_ssim'].uniq!
    return_hash['alt_condition_labels_ssim'].uniq!
    return_hash['full_hierarchy_condition_ssim'] = return_hash['preferred_condition_labels_ssim'] + return_hash['parent_hierarchy_condition_ssim']

    # Used for text searching
    return_hash['parent_hierarchy_condition_tesim'] = return_hash['parent_hierarchy_condition_ssim']
    return_hash['preferred_condition_labels_tesim'] = return_hash['preferred_condition_labels_ssim']
    return_hash['alt_condition_labels_tesim'] = return_hash['alt_condition_labels_ssim']

    return return_hash
  end

  def get_recursive_condition_level(ident)
    broader_list = []
    repo = ::Mei::Mesh.pop_graph(ident)
    repo.query(:subject=>::RDF::URI.new(ident), :predicate=>Mei::Mesh.nlm_namepace('broaderDescriptor')).each_statement do |result_statement|

      if !result_statement.object.literal? and result_statement.object.uri?
        broader_label = nil
        broader_uri = result_statement.object.to_s

        valid = false
        broader_repo = ::Mei::Mesh.pop_graph(broader_uri)
        broader_repo.query(:subject=>::RDF::URI.new(broader_uri)).each_statement do |broader_statement|
          if broader_statement.predicate.to_s == Mei::Mesh.rdfs_namepace('label')
            broader_label ||= broader_statement.object.value if broader_statement.object.literal?
          end

          if broader_statement.predicate.to_s == 'http://id.nlm.nih.gov/mesh/vocab#treeNumber'
            valid = true if broader_statement.object.value.match(/2017\/C........../)
          end
        end

        if valid
          broader_list += get_recursive_condition_level(broader_uri)
          broader_list << broader_label
        end
      end
    end
    return broader_list
  end

  def default_field(key, type)
    #Default is a stored string field that is indexed
    field_suffix = '_ssi'
    case type.to_s
      when "datetime"
        field_suffix = '_dtsi'
    end

    return {"#{key}#{field_suffix}"=>@user.send(key)}
  end

  def set_id
    return {'id'=>"demo:#{@user.id}"}
  end

  # Uses Geomash to parse the raw user input: https://github.com/projecthydra-labs/geomash
  # Sets up the solr fields for blacklight-maps: https://github.com/projectblacklight/blacklight-maps
  def tgn_uri
    return_hash = {}
    return_hash['subject_coordinates_geospatial'] = []
    return_hash['subject_geographic_hier_ssim'] = []
    return_hash['subject_geojson_facet_ssim'] = []
    return_hash['subject_geographic_ssim'] = []

    return_hash['tgn_uri_ssi'] = @user.tgn_uri
    detail_response = Geomash::TGN.get_tgn_data(@user.tgn_uri)

    return_hash['subject_coordinates_geospatial'] << "#{detail_response[:coords][:latitude]},#{detail_response[:coords][:longitude]}"

    if detail_response[:hier_geo]
      return_hash['subject_geographic_ssim'] << detail_response[:hier_geo][:city] if detail_response[:hier_geo][:city].present?
      return_hash['subject_geographic_ssim'] << detail_response[:hier_geo][:state] if detail_response[:hier_geo][:state].present?
      return_hash['subject_geographic_ssim'] << detail_response[:hier_geo][:state] if detail_response[:hier_geo][:province].present?
      return_hash['subject_geographic_ssim'] << detail_response[:hier_geo][:country] if detail_response[:hier_geo][:country].present?

      return_hash['subject_geographic_ssim'].uniq!
      return_hash['subject_geographic_hier_ssim'] << return_hash['subject_geographic_ssim'].join('||')
    else
      return_hash['subject_geographic_ssim'] << detail_response[:non_hier_geo] if detail_response[:non_hier_geo].present?
    end

    geojson_hash_base = {type: 'Feature', geometry: {type: 'Point'}}
    geojson_hash_base[:geometry][:coordinates] = [detail_response[:coords][:longitude],detail_response[:coords][:latitude]]
    geojson_hash_base[:properties] = {placename: return_hash['subject_geographic_ssim'].first}
    return_hash['subject_geojson_facet_ssim'].append(geojson_hash_base.to_json)


    return return_hash

  end

end