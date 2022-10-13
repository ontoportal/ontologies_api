require 'sinatra/base'
require 'json'

module Sinatra
  module Helpers
    module OntologyHelper

      #ISO_LANGUAGE_LIST = ::JSON.parse(IO.read("public/language_iso-639-1.json"))

      ##
      # Create a new OntologySubmission object based on the request data
      def create_submission(ont)
        params = @params

        submission_id = ont.next_submission_id

        # Create OntologySubmission
        ont_submission = instance_from_params(OntologySubmission, params)
        ont_submission.ontology = ont
        ont_submission.submissionId = submission_id

        # Get file info
        add_file_to_submission(ont, ont_submission)

        # Add new format if it doesn't exist
        if ont_submission.hasOntologyLanguage.nil?
          error 422, "You must specify the ontology format using the `hasOntologyLanguage` parameter" if params["hasOntologyLanguage"].nil? || params["hasOntologyLanguage"].empty?
          ont_submission.hasOntologyLanguage = OntologyFormat.find(params["hasOntologyLanguage"]).first
        end

        # Check if the naturalLanguage provided is a valid ISO-639-1 code (not used anymore, we let lexvo URI)
=begin
        if !ont_submission.naturalLanguage.nil?
          if ISO_LANGUAGE_LIST.has_key?(ont_submission.naturalLanguage.downcase)
            ont_submission.naturalLanguage = ont_submission.naturalLanguage.downcase
          else
            error 422, "You must specify a valid 2 digits language code (ISO-639-1) for naturalLanguage"
          end
        end
=end

        if ont_submission.valid?
          ont_submission.save
          cron = NcboCron::Models::OntologySubmissionParser.new
          cron.queue_submission(ont_submission, {all: true, params: params})
        else
          error 400, ont_submission.errors
        end

        ont_submission
      end


      ##
      # Add a file to the submission if a file exists in the params
      def add_file_to_submission(ont, submission)
        filename, tmpfile = file_from_request
        if tmpfile
          if filename.nil?
            error 400, "Failure to resolve ontology filename from upload file."
          end
          # Copy tmpfile to appropriate location
          ont.bring(:acronym) if ont.bring?(:acronym)
          # Ensure the ontology acronym is available
          if ont.acronym.nil?
            error 500, "Failure to resolve ontology acronym"
          end
          file_location = OntologySubmission.copy_file_repository(ont.acronym, submission.submissionId, tmpfile, filename)
          submission.uploadFilePath = file_location
        end
        return filename, tmpfile
      end
    end
  end
end

helpers Sinatra::Helpers::OntologyHelper
