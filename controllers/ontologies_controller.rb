class OntologiesController
  namespace "/ontologies" do

    ##
    # Display all ontologies
    get do
      if params["include"].nil? || params["include"].empty?
        onts = Ontology.all(:load_attrs => [:acronym])
      else
        onts = []
        containers = Ontology.all(:load_attrs => [:acronym])
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
    # Display all submissions of an ontology
    get '/:acronym/submissions' do
      ont = Ontology.find(params["acronym"])
      reply ont.submissions
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

      ont_submission = create_submission(ont)

      reply 201, ont_submission
    end

    ##
    # Create a new submission for an existing ontology
    post '/:acronym/submissions' do
      ont = Ontology.find(params["acronym"])
      error 422, "You must provide a valid `acronym` to create a new submission" if ont.nil?
      reply 201, create_submission(ont)
    end

    ##
    # Update an existing submission of an ontology
    patch '/:acronym/:ontology_submission_id' do
      ont = Ontology.find(params["acronym"])
      error 422, "You must provide an existing `acronym` to patch" if ont.nil?

      submission = ont.submission(params[:ontology_submission_id])
      error 422, "You must provide an existing `submissionId` to patch" if submission.nil?

      populate_from_params(submission, params)

      if submission.valid?
        submission.save
      else
        error 422, submission.errors
      end

      halt 204
    end

    ##
    # Update an existing submission of an ontology
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
    # Delete a specific ontology submission
    delete '/:acronym/:ontology_submission_id' do
      ont = Ontology.find(params["acronym"])
      error 422, "You must provide an existing `acronym` to delete" if ont.nil?
      submission = ont.submission(params[:ontology_submission_id])
      error 422, "You must provide an existing `submissionId` to delete" if submission.nil?
      submission.delete
      halt 204
    end

    ##
    # Download an ontology
    get '/:acronym/download' do
      submission = params[:ontology_submission_id]
      error 500, "Not implemented"
    end

    ##
    # Properties for given ontology
    get '/:acronym/properties' do
      error 500, "Not implemented"
    end

    private

    ##
    # Create a new OntologySubmission object based on the request data
    def create_submission(ont)
      params = @params

      # Get file info
      filename, tmpfile = file_from_request
      submission_id = ont.next_submission_id
      if tmpfile
        # Copy tmpfile to appropriate location
        file_location = OntologySubmission.copy_file_repository(params["acronym"], submission_id, tmpfile, filename)
      end

      SubmissionStatus.init
      OntologyFormat.init

      # Create OntologySubmission
      ont_submission = instance_from_params(OntologySubmission, params)
      ont_submission.ontology = ont
      ont_submission.submissionStatus = SubmissionStatus.find("UPLOADED")
      ont_submission.submissionId = submission_id
      ont_submission.pullLocation = params["pullLocation"].nil? ? nil : RDF::IRI.new(params["pullLocation"])
      ont_submission.uploadFilePath = file_location

      # Add new format if it doesn't exist
      if ont_submission.hasOntologyLanguage.nil?
        ont_submission.hasOntologyLanguage = OntologyFormat.find(params["hasOntologyLanguage"])
      end

      if ont_submission.valid?
        ont_submission.save
      else
        error 422, ont_submission.errors
      end

      ont_submission
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
