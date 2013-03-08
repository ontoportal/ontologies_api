class OntologiesController
  namespace "/ontologies" do

    ##
    # Display all ontologies
    get do
      if params["include"].nil? || params["include"].empty?
        onts = Ontology.all(:load_attrs => :defined)
      else
        onts = []
        containers = Ontology.all(:load_attrs => :defined)
        containers.each do |ont|
          onts << ont.latest_submission
        end
      end
      reply onts
    end

    ##
    # Display the most recent submission of the ontology
    get '/:acronym' do
      submission = params[:ontology_submission_id]
      ont = Ontology.find(params["acronym"])
      if submission
        ont = ont.submission(submission)
        error 404, "You must provide a valid `acronym` to retrieve an ontology" if ont.nil?
      end
      reply ont
    end

    ##
    # Ontologies get created via put because clients can assign an id (POST is only used where servers assign ids)
    put '/:acronym' do
      ont = Ontology.find(params["acronym"])
      if ont.nil?
        ont = instance_from_params(Ontology, params)
      else
        error 409, "Ontology already exists, to add a new submission, please POST to: /ontologies/#{params["acronym"]}/submission"
      end

      if ont.valid?
        ont.save
      else
        error 422, ont.errors
      end

      reply 201, ont
    end

    ##
    # Update an ontology
    patch '/:acronym' do
      ont = Ontology.find(params["acronym"])
      error 422, "You must provide an existing `acronym` to patch" if ont.nil?

      populate_from_params(ont, params)
      if ont.valid?
        ont.save
      else
        error 422, ont.errors
      end

      halt 204
    end

    ##
    # Delete an ontology and all its versions
    delete '/:acronym' do
      ont = Ontology.find(params["acronym"])
      error 422, "You must provide an existing `acronym` to delete" if ont.nil?
      ont.delete
      halt 204
    end

    ##
    # Download an ontology
    get '/:acronym/download' do
      error 500, "Not implemented"
    end

    ##
    # Properties for given ontology
    get '/:acronym/properties' do
      error 500, "Not implemented"
    end

  end
end
