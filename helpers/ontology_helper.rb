require 'sinatra/base'

module Sinatra
  module Helpers
    module OntologyHelper
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

        if ont_submission.valid?
          ont_submission.save
          cron = NcboCron::Models::OntologySubmissionParser.new
          cron.queue_submission(ont_submission, {all: true})
        else
          error 400, ont_submission.errors
        end

        ont_submission
      end

      ##
      # Checks to see if the request has a file attached
      def request_has_file?
        @params.any? {|p,v| v.instance_of?(Hash) && v.key?(:tempfile) && v[:tempfile].instance_of?(Tempfile)}
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

      def get_parse_log_file(submission)
        submission.bring(ontology:[:acronym])
        ontology = submission.ontology

        parse_log_folder = File.join(LinkedData.settings.repository_folder, "parse-logs")
        Dir.mkdir(parse_log_folder) unless File.exist? parse_log_folder
        file_log_path = File.join(parse_log_folder, "#{ontology.acronym}-#{submission.submissionId}-#{DateTime.now.strftime("%Y%m%d_%H%M%S")}.log")
        return File.open(file_log_path,"w")
      end

      def raw_ontologies_report(supress_error=false)
        report_path = NcboCron.settings.ontology_report_path
        report = {}

        if !supress_error && (report_path.nil? || report_path.empty?)
          error 500, "Ontologies report path not set in config"
        end

        if !supress_error && !File.exist?(report_path)
          error 500, "Ontologies report file #{report_path} not found"
        end

        unless report_path.nil? || report_path.empty? || !File.exist?(report_path)
          json_string = ::IO.read(report_path)
          report = ::JSON.parse(json_string)
        end
        report
      end

    end
  end
end

helpers Sinatra::Helpers::OntologyHelper
