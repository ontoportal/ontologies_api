require 'sinatra/base'

module Sinatra
  module Helpers
    module OntologyHelper
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

        # Create OntologySubmission
        ont_submission = instance_from_params(OntologySubmission, params)
        ont_submission.ontology = ont
        ont_submission.submissionId = submission_id
        ont_submission.pullLocation = params["pullLocation"].nil? ? nil : RDF::IRI.new(params["pullLocation"])
        ont_submission.uploadFilePath = file_location

        # Add new format if it doesn't exist
        if ont_submission.hasOntologyLanguage.nil?
          error 422, "You must specify the ontology format using the `hasOntologyLanguage` parameter" if params["hasOntologyLanguage"].nil? || params["hasOntologyLanguage"].empty?
          ont_submission.hasOntologyLanguage = OntologyFormat.find(params["hasOntologyLanguage"]).first
        end

        if ont_submission.valid?
          ont_submission.save
          cron = NcboCron::Models::OntologySubmissionParser.new
          cron.queue_submission(ont_submission, actions=[:all])
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

      def get_parse_log_file(submission)
        submission.bring(ontology:[:acronym])
        ontology = submission.ontology

        parse_log_folder = File.join(LinkedData.settings.repository_folder, "parse-logs")
        Dir.mkdir(parse_log_folder) unless File.exist? parse_log_folder
        file_log_path = File.join(parse_log_folder, "#{ontology.acronym}-#{submission.submissionId}-#{DateTime.now.strftime("%Y%m%d_%H%M%S")}.log")
        return File.open(file_log_path,"w")
      end
    end
  end
end

helpers Sinatra::Helpers::OntologyHelper
