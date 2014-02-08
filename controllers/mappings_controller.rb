class MappingsController < ApplicationController

  # Get mappings for a class
  get '/ontologies/:ontology/classes/:cls/mappings' do
    ontology = ontology_from_acronym(@params[:ontology])
    submission = ontology.latest_submission
    cls_id = @params[:cls]
    cls = LinkedData::Models::Class.find(RDF::URI.new(cls_id)).in(submission).first
    reply 404, "Class with id `#{class_id}` not found in ontology `#{acronym}`" if cls.nil?


    mappings = LinkedData::Models::Mapping.where(terms: [ontology: ontology, term: cls.id ])
                                 .include(terms: [ :term, ontology: [ :acronym ] ])
                                 .include(process: [:name, :owner ])
                                 .all

    res = filter_mappings_with_no_ontology(mappings)
    reply res
  end

  # Get mappings for an ontology
  get '/ontologies/:ontology/mappings' do
    ontology = ontology_from_acronym(@params[:ontology])
    page, size = page_params
    mappings = LinkedData::Models::Mapping.where(terms: [ontology: ontology ])
                                 .include(terms: [ :term, ontology: [ :acronym ] ])
                                 .include(process: [:name, :owner ])
                                 .page(page,size)
                                 .no_count
                                 .all
    reply filter_mappings_with_no_ontology(mappings)
  end

  namespace "/mappings" do
    # Display all mappings
    get do
      ontologies = ontology_objects_from_params
      if ontologies.length != 2
        error(400, "/mappings/ endpoint only supports filtering on two ontologies")
      end

      page, size = page_params

      mappings = LinkedData::Models::Mapping.where(terms: [ontology: ontologies.first ])
      if ontologies.length > 1
        mappings.and(terms: [ontology: ontologies[1] ])
      end
      mappings = mappings.include(terms: [ :term, ontology: [ :acronym ] ])
                  .include(process: [:name, :owner ])
                  .page(page,size)
                  .no_count
                  .all
      reply filter_mappings_with_no_ontology(mappings)
    end

    get "/recent" do
      size = params[:size] || 5
      if size > 50
        error 422, "Recent mappings only processes calls under 50"
      else
        mappings = LinkedData::Mappings.recent_user_mappings(size)
        reply filter_mappings_with_no_ontology(mappings)
      end
    end

    # Display a single mapping
    get '/:mapping' do
      mapping_id = RDF::URI.new(params[:mapping])
      mapping = LinkedData::Models::Mapping.find(mapping_id)
                  .include(terms: [:ontology, :term ])
                  .include(process: LinkedData::Models::MappingProcess.attributes)
                  .first
      if mapping
        onts = mapping.terms.map {|t| t.ontology }
        LinkedData::Models::Ontology.where.models(onts).include(:acronym).all
        reply filter_mappings_with_no_ontology([mapping]).first
      else
        error(404, "Mapping with id `#{mapping_id.to_s}` not found")
      end
    end

    # Create a new mapping
    post do
      error(400, "Input does not contain terms") if !params[:terms]
      error(400, "Input does not contain at least 2 terms") if params[:terms].length < 2
      error(400, "Input does not contain mapping relation") if !params[:relation]
      error(400, "Input does not contain user creator ID") if !params[:creator]
      params[:terms].each do |term|
        if !term[:term] || !term[:ontology]
          error(400,"Every term must have at least one term ID and a ontology ID or acronym")
        end
        if !term[:term].is_a?(Array)
          error(400,"Term IDs must be contain in Arrays")
        end
        o = term[:ontology]
        o =  o.start_with?("http://") ? o : ontology_uri_from_acronym(o)
        o = LinkedData::Models::Ontology.find(RDF::URI.new(o))
                                        .include(submissions: [:submissionId, :submissionStatus]).first
        error(400, "Ontology with ID `#{term[:ontology]}` not found") if o.nil?
        term[:term].each do |id|
          error(400, "Term ID #{id} is not valid, it must be an HTTP URI") if !id.start_with?("http://")
          submission = o.latest_submission
          error(400, "Ontology with id #{term[:ontology]} does not have parsed valid submission") if !submission
          c = LinkedData::Models::Class.find(RDF::URI.new(id)).in(o.latest_submission)
          error(400, "Class ID `#{id}` not found in `#{submission.id.to_s}`") if c.nil?
        end
      end
      user_id = params[:creator].start_with?("http://") ? params[:creator].split("/")[-1] : params[:creator]
      user_creator = LinkedData::Models::User.find(user_id).include(:username).first
      error(400, "User with id `#{params[:creator]}` not found") if user_creator.nil?
      process = LinkedData::Models::MappingProcess.new(:creator => user_creator, :name => "REST Mapping")
      process.relation = RDF::URI.new(params[:relation])
      process.date = DateTime.now
      process_fields = [:source,:source_name, :comment]
      process_fields.each do |att|
        process.send("#{att}=",params[att]) if params[att]
      end
      process.save
      term_mappings = []
      params[:terms].each do |term|
        ont_acronym = term[:ontology].start_with?("http://") ? term[:ontology].split("/")[-1] : term[:ontology]
        term_mappings << LinkedData::Mappings.create_term_mapping(term[:term].map {|x| RDF::URI.new(x) },ont_acronym)
      end
      mapping_id = LinkedData::Mappings.create_mapping(term_mappings)
      LinkedData::Mappings.connect_mapping_process(mapping_id, process)
      mapping = LinkedData::Models::Mapping.find(mapping_id)
                  .include(terms: [:ontology, :term ])
                  .include(process: LinkedData::Models::MappingProcess.attributes)
                  .first
      onts = mapping.terms.map { |x| x.ontology }
      LinkedData::Models::Ontology.where.models(onts).include(:acronym).all
      reply(201, mapping)
    end

    # Delete a mapping
    delete '/:mapping' do
      mapping_id = RDF::URI.new(replace_url_prefix(params[:mapping]))
      mapping = LinkedData::Models::Mapping.find(mapping_id)
                  .include(terms: [:ontology, :term ])
                  .include(process: LinkedData::Models::MappingProcess.attributes)
                  .first

      if mapping.nil?
        error(404, "Mapping with id `#{mapping_id.to_s}` not found")
      else
        deleted = false
        disconnected = 0
        mapping.process.each do |p|
          if p.date
            disconnected += 1
            mapping_updated = LinkedData::Mappings.disconnect_mapping_process(mapping.id,p)
            if mapping_updated.process.length == 0
              deleted = true
              LinkedData::Mappings.delete_mapping(mapping_updated)
              break
            end
          end
        end

        if deleted
          halt 204
        else
          if disconnected > 0
            halt 204
          else
            reply(400, "This mapping only contains automatic processes. Nothing has been deleted")
          end
        end
      end
    end
  end

  namespace "/mappings/statistics" do

    get '/ontologies' do
      expires 86400, :public
      reply LinkedData::Mappings.mapping_counts_per_ontology()
    end

    # Statistics for an ontology
    get '/ontologies/:ontology' do
      expires 86400, :public
      ontology = ontology_from_acronym(@params[:ontology])
      reply LinkedData::Mappings.mapping_counts_for_ontology(ontology)
    end

    # Classes with lots of mappings
    get '/ontologies/:ontology/popular_classes' do
    end

    # Users with lots of mappings
    get '/ontologies/:ontology/users' do
    end
  end

end
