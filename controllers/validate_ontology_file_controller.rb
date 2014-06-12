require 'multi_json'

class ValidateOntologyFileController < ApplicationController
  namespace "/validate_ontology_file" do
    post do
      error 401, "Must provide ontology file using `ontology_file` field" unless params["ontology_file"]
      buf = StringIO.new
      log = Logger.new(buf)
      tmpdir = Dir.tmpdir
      ontfile = params["ontology_file"][:tempfile]
      ontfilename = params["ontology_file"][:filename]
      process_id = "#{Time.now.to_i}_#{ontfilename}"
      pid = fork do
        parser = LinkedData::Parser::OWLAPICommand.new(ontfile.path, tmpdir, logger: log)
        error = ["error not found"]
        begin
          missing_imports = parser.call_owlapi_java_command[1]
        ensure
          buf.rewind
          error_lines = buf.read.split("\n")
          error = extract_error_message(error_lines, format(ontfilename))
          ontfile.close
        end
        error.unshift("Could not download imports: #{missing_imports.join(",")}") if missing_imports && !missing_imports.empty?
          redis.setex process_id, 360, MultiJson.dump(error)
      end
      Process.detach(pid)
      redis.setex process_id, 360, MultiJson.dump("processing")
      reply(process_id: process_id)
    end

    get "/:process_id" do
      errors = MultiJson.load(redis.get(params["process_id"]))
      if errors.nil?
        error 404, "Process id #{params["process_id"]} does not exit"
      else
        reply errors
      end
    end

    private

    def redis
      Redis.new(host: Annotator.settings.annotator_redis_host, port: Annotator.settings.annotator_redis_port)
    end

    ERROR_FORMAT_MAP = {"obo" => "OBOFormatOWLAPIParser", "owl" => "OWLXMLParser", "rdf" => "RDFXMLParser"}
    def extract_error_message(error_lines, format)
      error = []
      found_error = false
      error_lines.each do |line|
        next if line.empty?
        if found_error
          break if line.start_with?("--------") || line.start_with?("org.semanticweb.owlapi.io.UnparsableOntologyException")
          error << line
        end
        if line.start_with?("Parser:")
          error_type = line.split(" ")[1]
          if error_type == ERROR_FORMAT_MAP[format]
            found_error = true
          end
        end
      end
      error
    end

    def format(filename)
      filename.split(".").last.downcase
    end
  end
end