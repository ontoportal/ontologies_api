class MappingsController < ApplicationController

  # Get mappings for a class
  get '/ontologies/:ontology/classes/:cls/mappings' do
    ontology = ontology_from_acronym(@params[:ontology])
    ontology = LinkedData::Models::Ontology.find(acronym).first

    cls_id = @params[:cls]
    cls = LinkedData::Models::Class.find(RDF::URI.new(cls_id)).in(submission).first
    reply 404, "Class with id `#{class_id}` not found in ontology `#{acronym}`" if cls.nil?


    mappings = LinkedData::Models::Mapping.where(terms: [ontology: ontology, term: cls.id ])
                                 .include(terms: [ :term, ontology: [ :acronym ] ])
                                 .include(process: [:name, :owner ])
                                 .all

    reply mappings
  end

  # Get mappings for an ontology
  get '/ontologies/:ontology/mappings' do
    ontology = ontology_from_acronym(@params[:ontology])
    page, size = page_params
    mappings = LinkedData::Models::Mapping.where(terms: [ontology: ontology ])
                                 .include(terms: [ :term, ontology: [ :acronym ] ])
                                 .include(process: [:name, :owner ])
                                 .page(page,size)
                                 .all
    reply mappings
  end

  namespace "/mappings" do
    # Display all mappings
    get do
    end

    # Display a single mapping
    get '/:mapping' do
    end

    # Create a new mapping
    post do
    end

    # Update via delete/create for an existing submission of an mapping
    put '/:mapping' do
    end

    # Update an existing submission of an mapping
    patch '/:mapping' do
    end

    # Delete a mapping
    delete '/:mapping' do
    end
  end

  namespace "/mappings/statistics" do
    # List recent mappings
    get '/recent' do
    end

    # Statistics for an ontology
    get '/ontologies/:ontology' do
      ontology = ontology_from_acronym(@params[:ontology])
    end

    # Classes with lots of mappings
    get '/ontologies/:ontology/popular_classes' do
    end

    # Users with lots of mappings
    get '/ontologies/:ontology/users' do
    end
  end

  def ontology_from_acronym(acronym)
    ontology = LinkedData::Models::Ontology.find(acronym).first
    reply 404, "Ontology with acronym `#{acronym}` not found" if ontology.nil?
    submission = ontology.latest_submission
    reply 400, "No parsed submissions for ontology with acronym `#{acronym}`" if submission.nil?
    return ontology
  end

end
