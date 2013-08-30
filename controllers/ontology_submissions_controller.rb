class OntologySubmissionsController < ApplicationController
  get "/submissions" do
    check_last_modified_collection(LinkedData::Models::OntologySubmission)
    #using appplication_helper method
    reply retrieve_latest_submissions.values
  end

  ##
  # Create a new submission for an existing ontology
  post "/submissions" do
    ont = Ontology.find(uri_as_needed(params["ontology"])).include(Ontology.goo_attrs_to_load).first
    error 422, "You must provide a valid `acronym` to create a new submission" if ont.nil?
    reply 201, create_submission(ont)
  end

  namespace "/ontologies/:acronym/submissions" do

    ##
    # Display all submissions of an ontology
    get do
      ont = Ontology.find(params["acronym"]).include(:acronym).first
      check_last_modified_segment(LinkedData::Models::OntologySubmission, [ont.acronym])
      ont.bring(submissions: OntologySubmission.goo_attrs_to_load(includes_param))
      reply ont.submissions
    end

    ##
    # Create a new submission for an existing ontology
    post do
      ont = Ontology.find(params["acronym"]).include(Ontology.attributes).first
      error 422, "You must provide a valid `acronym` to create a new submission" if ont.nil?
      reply 201, create_submission(ont)
    end

    ##
    # Display a submission
    get '/:ontology_submission_id' do
      ont = Ontology.find(params["acronym"]).include(:acronym).first
      check_last_modified_segment(LinkedData::Models::OntologySubmission, [ont.acronym])
      ont.bring(:submissions)
      ont_submission = ont.submission(params["ontology_submission_id"])
      error 404, "`submissionId` not found" if ont_submission.nil?
      ont_submission.bring(*OntologySubmission.goo_attrs_to_load(includes_param))
      reply ont_submission
    end

    ##
    # Update an existing submission of an ontology
    patch '/:ontology_submission_id' do
      ont = Ontology.find(params["acronym"]).first
      error 422, "You must provide an existing `acronym` to patch" if ont.nil?

      submission = ont.submission(params[:ontology_submission_id])
      error 422, "You must provide an existing `submissionId` to patch" if submission.nil?

      submission.bring(*OntologySubmission.attributes)
      populate_from_params(submission, params)

      if submission.valid?
        submission.save
      else
        error 422, submission.errors
      end

      halt 204
    end

    ##
    # Delete a specific ontology submission
    delete '/:ontology_submission_id' do
      ont = Ontology.find(params["acronym"]).first
      error 422, "You must provide an existing `acronym` to delete" if ont.nil?
      submission = ont.submission(params[:ontology_submission_id])
      error 422, "You must provide an existing `submissionId` to delete" if submission.nil?
      submission.delete
      halt 204
    end

    ##
    # Trigger the parsing of ontology submission ID
    post '/:ontology_submission_id/parse' do
      ont = Ontology.find(params["acronym"]).first
      error 422, "You must provide an existing `acronym` to parse a submission" if ont.nil?
      error 422, "You must provide a `submissionId`" if params[:ontology_submission_id].nil?
      submission = ont.submission(params[:ontology_submission_id])
      error 422, "You must provide an existing `submissionId` to parse" if submission.nil?

      #TODO: @palexander All this can be moved outside of the controller
      Thread.new do
        log_file = get_parse_log_file(submission)
        logger_for_parsing = CustomLogger.new(log_file)
        logger_for_parsing.level = Logger::DEBUG
        begin
          submission.process_submission(logger_for_parsing, process_rdf=true, index_search=true, run_metrics=true)
        rescue => e
          if submission.valid?
            submission.save
          else
            mess = "Error saving ERROR status for submission #{submission.resource_id.value}"
            logger.error(mess)
            logger_for_parsing.error(mess)
          end
          log_file.flush()
          log_file.close()
        end
      end
      #TODO: end

      message = { "message" => "Parse triggered as background process. Check ontology status for parsing progress." }
      reply 200, message
    end

    ##
    # Download a submission
    # get '/:ontology_submission_id/download' do
    #   error 500, "Not implemented"
    # end

    ##
    # Properties for given submission
    # get '/:ontology_submission_id/properties' do
    #   error 500, "Not implemented"
    # end

  end
end
