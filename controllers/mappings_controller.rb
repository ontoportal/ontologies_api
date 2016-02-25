class MappingsController < ApplicationController

  LinkedData.settings.interportal_hash ||= {}

  # Get mappings for a class
  get '/ontologies/:ontology/classes/:cls/mappings' do
    ontology = ontology_from_acronym(@params[:ontology])
    submission = ontology.latest_submission
    cls_id = @params[:cls]
    cls = LinkedData::Models::Class.find(RDF::URI.new(cls_id)).in(submission).first
    if cls.nil?
      error(404, "Class with id `#{cls_id}` not found in ontology")
    end

    mappings = LinkedData::Mappings.mappings_ontology(submission,
                                                      0,0,
                                                      cls.id)
    populate_mapping_classes(mappings.to_a)
    reply mappings
  end

  # Get mappings for an ontology
  get '/ontologies/:ontology/mappings' do
    ontology = ontology_from_acronym(@params[:ontology])
    if ontology.nil?
        error(404, "Ontology not found")
    end
    page, size = page_params
    submission = ontology.latest_submission
    if submission.nil?
        error(404, "Submission not found for ontology " + ontology.acronym)
    end
    mappings = LinkedData::Mappings.mappings_ontology(submission,
                                                      page,size,
                                                      nil)
    populate_mapping_classes(mappings)
    reply mappings
  end

  namespace "/mappings" do
    # Display all mappings
    get do
      #ontologies = ontology_objects_from_params
      if params[:ontologies].nil?
        error(400,
              "/mappings/ endpoint only supports filtering " +
                  "on two ontologies using `?ontologies=ONT1,ONT2`")
      end
      ontologies = params[:ontologies].split(",")
      if ontologies.length != 2
        error(400,
              "/mappings/ endpoint only supports filtering " +
              "on two ontologies using `?ontologies=ONT1,ONT2`")
      end

      acr1 = ontologies[0]
      acr2 = ontologies[1]

      page, size = page_params
      ont1 = LinkedData::Models::Ontology.find(acr1).first
      ont2 = LinkedData::Models::Ontology.find(acr2).first

      if ont1.nil?
        # If the ontology given in param is external (mappings:external) or interportal (interportal:acronym)
        if acr1 == LinkedData::Models::ExternalClass.url_param_str
          sub1 = LinkedData::Models::ExternalClass.graph_uri.to_s
        elsif acr1.start_with?(LinkedData::Models::InterportalClass.base_url_param_str)
          sub1 = LinkedData::Models::InterportalClass.graph_uri(acr1.split(":")[-1]).to_s
        else
          error(404, "Submission not found for ontology #{acr1}")
        end
      else
        sub1 = ont1.latest_submission
        if sub1.nil?
          error(404, "Ontology #{acr1} not found")
        end
      end
      if ont2.nil?
        # If the ontology given in param is external (mappings:external) or interportal (interportal:acronym)
        if acr2 == LinkedData::Models::ExternalClass.url_param_str
          sub2 = LinkedData::Models::ExternalClass.graph_uri
        elsif acr2.start_with?(LinkedData::Models::InterportalClass.base_url_param_str)
          sub2 = LinkedData::Models::InterportalClass.graph_uri(acr2.split(":")[-1])
        else
          error(404, "Ontology #{acr2} not found")
        end
      else
        sub2 = ont2.latest_submission
        if sub2.nil?
          error(404, "Submission not found for ontology #{acr2}")
        end
      end
      mappings = LinkedData::Mappings.mappings_ontologies(sub1,sub2,
                                                          page,size)
      populate_mapping_classes(mappings)
      reply mappings
    end

    get "/recent" do
      check_last_modified_collection(LinkedData::Models::RestBackupMapping)
      size = params[:size] || 5
      size = Integer(size)
      if size > 50
        error 422, "Recent mappings only processes calls under 50"
      else
        mappings = LinkedData::Mappings.recent_rest_mappings(size + 15)
        populate_mapping_classes(mappings)
        reply mappings[0..size-1]
      end
    end

    # Display a single mapping - only rest
    get '/:mapping' do
      mapping_id = nil
      if params[:mapping] and params[:mapping].start_with?("http")
        mapping_id = RDF::URI.new(params[:mapping])
      else
        mapping_id =
          "http://data.bioontology.org/rest_backup_mappings/#{params[:mapping]}"
        mapping_id = RDF::URI.new(mapping_id)
      end
      mapping = LinkedData::Mappings.get_rest_mapping(mapping_id)
      if mapping
        reply populate_mapping_classes([mapping].first)
      else
        error(404, "Mapping with id `#{mapping_id.to_s}` not found")
      end
    end

    # Create a new mapping
    post do
      error(400, "Input does not contain classes") if !params[:classes]
      if params[:classes].length > 2
        error(400, "Input does not contain at least 2 terms")
      end
      error(400, "Input does not contain mapping relation") if !params[:relation]
      if params[:relation].kind_of?(Array)
        error(400, "Input contains too many mapping relations (max 5)") if params[:relation].length > 5
        params[:relation].each do |relation|
          begin
            URI(relation)
          rescue URI::InvalidURIError => e
            error(400, "#{relation} is not a valid URI for relations.")
          end
        end
      end
      error(400, "Input does not contain user creator ID") if !params[:creator]
      classes = []
      mapping_process_name = "REST Mapping"
      params[:classes].each do |class_id,ontology_id|
        interportal_prefix = ontology_id.split(":")[0]
        if ontology_id.start_with? "ext:"
          #TODO: check if the ontology is a well formed URI
          # Just keep the source and the class URI if the mapping is external or interportal and change the mapping process name
          error(400, "Impossible to map 2 classes outside of BioPortal") if mapping_process_name != "REST Mapping"
          mapping_process_name = "External Mapping"
          ontology_uri = ontology_id.sub("ext:", "")
          if !uri?(ontology_uri)
            error(400, "Ontology URI '#{ontology_uri.to_s}' is not valid")
          end
          if !uri?(class_id)
            error(400, "Class URI '#{class_id.to_s}' is not valid")
          end
          ontology_uri = CGI.escape(ontology_uri)
          c = {:source => "ext", :ontology => ontology_uri, :id => class_id}
          classes << c
        elsif LinkedData.settings.interportal_hash.has_key?(interportal_prefix)
            #Check if the prefix is contained in the interportal hash to create a mapping to this bioportal
            error(400, "Impossible to map 2 classes outside of BioPortal") if mapping_process_name != "REST Mapping"
            mapping_process_name = "Interportal Mapping #{interportal_prefix}"
            ontology_acronym = ontology_id.sub("#{interportal_prefix}:", "")
            if validate_interportal_mapping(class_id, ontology_acronym, interportal_prefix)
              c = {:source => interportal_prefix, :ontology => ontology_acronym, :id => class_id}
              classes << c
            else
              error(400, "Interportal combination of class and ontology don't point to a valid class")
            end
        else
          o = ontology_id
          o =  o.start_with?("http://") ? ontology_id :
              ontology_uri_from_acronym(ontology_id)
          o = LinkedData::Models::Ontology.find(RDF::URI.new(o))
                  .include(submissions:
                               [:submissionId, :submissionStatus]).first
          if o.nil?
            error(400, "Ontology with ID `#{ontology_id}` not found")
          end
          submission = o.latest_submission
          if submission.nil?
            error(400,
                  "Ontology with id #{ontology_id} does not have parsed valid submission")
          end
          submission.bring(ontology: [:acronym])
          c = LinkedData::Models::Class.find(RDF::URI.new(class_id))
                  .in(submission)
                  .first
          if c.nil?
            error(400, "Class ID `#{class_id}` not found in `#{submission.id.to_s}`")
          end
          classes << c
        end
      end
      user_id = params[:creator].start_with?("http://") ?
                    params[:creator].split("/")[-1] : params[:creator]
      user_creator = LinkedData::Models::User.find(user_id)
                          .include(:username).first
      if user_creator.nil?
        error(400, "User with id `#{params[:creator]}` not found")
      end
      process = LinkedData::Models::MappingProcess.new(
                    :creator => user_creator, :name => mapping_process_name)
      relations_array = []
      if !params[:relation].kind_of?(Array)
        relations_array.push(RDF::URI.new(params[:relation]))
      else
        params[:relation].each do |relation|
          relations_array.push(RDF::URI.new(relation))
        end
      end
      error(400, "Mapping already exists") if LinkedData::Mappings.check_mapping_exist(classes, relations_array)
      process.relation = relations_array
      process.date = DateTime.now
      process_fields = [:source,:source_name, :comment]
      process_fields.each do |att|
        process.send("#{att}=",params[att]) if params[att]
      end
      process.save
      mapping = LinkedData::Mappings.create_rest_mapping(classes,process)
      reply(201, mapping)
    end

    # Delete a mapping
    delete '/:mapping' do
      mapping_id = RDF::URI.new(replace_url_prefix(params[:mapping]))
      mapping = LinkedData::Mappings.delete_rest_mapping(mapping_id)
      if mapping.nil?
        error(404, "Mapping with id `#{mapping_id.to_s}` not found")
      else
        halt 204
      end
    end
  end

  namespace "/mappings/statistics" do

    get '/ontologies' do
      expires 86400, :public
      persistent_counts = {}
      f = Goo::Filter.new(:pair_count) == false
      LinkedData::Models::MappingCount.where.filter(f)
      .include(:ontologies,:count)
      .all
      .each do |m|
        persistent_counts[m.ontologies.first] = m.count
      end
      reply persistent_counts
    end

    # Statistics for an ontology
    get '/ontologies/:ontology' do
      expires 86400, :public
      ontology = ontology_from_acronym(@params[:ontology])
      if ontology.nil?
        error(404, "Ontology #{@params[:ontology]} not found")
      end
      sub = ontology.latest_submission
      if sub.nil?
        error(404, "Ontology #{@params[:ontology]} does not have a submission")
      end

      persistent_counts = {}
      LinkedData::Models::MappingCount.where(pair_count: true)
                                      .and(ontologies: ontology.acronym)
      .include(:ontologies,:count)
      .all
      .each do |m|
        other = m.ontologies.first
        if other == ontology.acronym
          other = m.ontologies[1]
        end
        persistent_counts[other] = m.count
      end
      reply persistent_counts
    end

    # Statistics for interportal mappings
    get '/interportal/:ontology' do
      expires 86400, :public
      if !LinkedData.settings.interportal_hash.has_key?(@params[:ontology])
        error(404, "Interportal appliance #{@params[:ontology]} is not configured")
      end
      ontology_id = LinkedData::Models::InterportalClass.graph_uri(@params[:ontology]).to_s
      persistent_counts = {}
      LinkedData::Models::MappingCount.where(pair_count: true)
          .and(ontologies: ontology_id)
          .include(:ontologies,:count)
          .all
          .each do |m|
        other = m.ontologies.first
        if other == ontology_id
          other = m.ontologies[1]
        end
        persistent_counts[other] = m.count
      end
      reply persistent_counts
    end

    # Statistics for external mappings
    get '/external' do
      expires 86400, :public
      ontology_id = LinkedData::Models::ExternalClass.graph_uri.to_s
      persistent_counts = {}
      LinkedData::Models::MappingCount.where(pair_count: true)
          .and(ontologies: ontology_id)
          .include(:ontologies,:count)
          .all
          .each do |m|
        other = m.ontologies.first
        if other == ontology_id
          other = m.ontologies[1]
        end
        persistent_counts[other] = m.count
      end
      reply persistent_counts
    end
  end
end
