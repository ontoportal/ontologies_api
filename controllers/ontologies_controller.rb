class OntologiesController
  namespace "/ontologies" do
    # Display all ontologies
    get do
    end

    # Display the most recent submission of the ontology
    get '/:ontology' do
      submission = params[:ontology_submission_id]
    end

    # Display all submissions of an ontology
    get '/:ontology/submissions' do
      submission = params[:ontology_submission_id]
    end

    # Ontologies get created via put because clients can assign an id (POST is only used where servers assign ids)
    put '/:ontology' do
      filename, tmpfile = file_from_request
    end

    # Create a new submission for an existing ontology
    post '/:ontology/submission' do
    end

    # Update via delete/create for an existing submission of an ontology
    put '/:ontology/:ontology_submission_id' do
    end

    # Update an existing submission of an ontology
    patch '/:ontology/:ontology_submission_id' do
    end

    # Delete an ontology and all its versions
    delete '/:ontology' do
    end

    # Delete a specific ontology submission
    delete '/:ontology/:ontology_submission_id' do
    end

    # Download an ontology
    get '/:ontology/download' do
      submission = params[:ontology_submission_id]
    end

    # Properties for given ontology
    get '/:ontology/properties' do
    end

    private

    ##
    # Looks for a file that was included as a multipart in a request
    def file_from_request
      @params.each do |param, value|
        if value.instance_of?(Hash) && value.has_key?(:tempfile) && value[:tempfile].instance_of?(Tempfile)
          return value[:filename], value[:tempfile]
        end
      end
      nil, nil
    end

  end
end