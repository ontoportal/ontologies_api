class OntologiesController
  namespace "/ontologies" do
    # Display all ontologies
    get do
    end

    # Display the most recent submission of the ontology
    get '/:acronym' do
      submission = params[:ontology_submission_id]
    end

    # Display all submissions of an ontology
    get '/:acronym/submissions' do
      submission = params[:ontology_submission_id]
    end

    # Ontologies get created via put because clients can assign an id (POST is only used where servers assign ids)
    end

    # Create a new submission for an existing ontology
    post '/:acronym/submission' do
    end

    # Update via delete/create for an existing submission of an ontology
    put '/:acronym/:ontology_submission_id' do
    end

    # Update an existing submission of an ontology
    patch '/:acronym/:ontology_submission_id' do
    end

    # Delete an ontology and all its versions
    delete '/:acronym' do
    end

    # Delete a specific ontology submission
    delete '/:acronym/:ontology_submission_id' do
    end

    # Download an ontology
    get '/:acronym/download' do
      submission = params[:ontology_submission_id]
    end

    # Properties for given ontology
    get '/:acronym/properties' do
    end

    private

    ##
    # Create a new OntologySubmission object based on the request data
      params = @params

      filename, tmpfile = file_from_request
        file_location = OntologySubmission.copy_file_repository(params["acronym"], submission_id, tmpfile, filename)

      ont_submission = instance_from_params(OntologySubmission, params)
      ont_submission.ontology = ont
      ont_submission.submissionId = submission_id
      ont_submission.pullLocation = params["pullLocation"].nil? ? nil : RDF::IRI.new(params["pullLocation"])
      ont_submission.uploadFilePath = file_location

      # Add new format if it doesn't exist
      if ont_submission.ontologyFormat.nil?
        ont_submission.ontologyFormat = OntologyFormat.new(acronym: params["ontologyFormat"])
      end

        ont_submission.save
        error 400, ont_submission.errors
      end
    end

    ##
    # Looks for a file that was included as a multipart in a request
    def file_from_request
      @params.each do |param, value|
        if value.instance_of?(Hash) && value.has_key?(:tempfile) && value[:tempfile].instance_of?(Tempfile)
          return value[:filename], value[:tempfile]
        end
      end
      return nil, nil
    end

  end
end