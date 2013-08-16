require 'sinatra/base'
require 'date'

module Sinatra
  module Helpers
    module ApplicationHelper

      ##
      # Escape text for use in html
      def h(text)
        Rack::Utils.escape_html(text)
      end

      ##
      # Populate +obj+ using values from +params+
      # Will also try to find related objects using a Goo lookup.
      # TODO: Currerntly, this allows for mass-assignment of everything, which will permit
      # users to overwrite any attribute, including things like passwords.
      def populate_from_params(obj, params)
        return if obj.nil?

        params.each do |attribute, value|
          next if value.nil?

          attribute = attribute.to_sym
          attr_cls = obj.class.range(attribute)
          attribute_settings = obj.class.attribute_settings(attribute)

          # Try to find dependent Goo objects, but only if the naming is not done via Proc
          # If naming is done via Proc, then try to lookup the Goo object using a hash of attributes
          if attr_cls == LinkedData::Models::Class
            value = value.is_a?(Array) ? value : [value]
            new_value = []
            value.each do |cls|
              sub = LinkedData::Models::Ontology.find(uri_as_needed(cls["ontology"])).first.latest_submission
              new_value << LinkedData::Models::Class.find(cls["class"]).in(sub).first
            end
            value = new_value
          elsif attr_cls && !value.is_a?(Hash)
            # Replace the initial value with the object, handling Arrays as appropriate
            if value.is_a?(Array)
              value = value.map {|e| attr_cls.find(uri_as_needed(e)).include(attr_cls.attributes).first}
            else
              value = attr_cls.find(uri_as_needed(value)).include(attr_cls.attributes).first
            end
          elsif attr_cls
            # Check to see if the resource exists in the triplestore
            retreived_value = attr_cls.where(value.symbolize_keys).to_a

            if retreived_value.empty?
              # Create a new object and save if one didn't exist
              retreived_value = populate_from_params(attr_cls.new, value.symbolize_keys)
              retreived_value.save
            end
            value = retreived_value
          elsif attribute_settings && attribute_settings[:enforce] && attribute_settings[:enforce].include?(:date_time)
            # TODO: Remove this awful hack when obj.class.model_settings[:range][attribute] contains DateTime class
            value = DateTime.parse(value)
          elsif attribute_settings && attribute_settings[:enforce] && attribute_settings[:enforce].include?(:uri)
            # TODO: Remove this awful hack when obj.class.model_settings[:range][attribute] contains RDF::IRI class
            value = RDF::IRI.new(value)
          end

          # Don't populate naming attributes if they exist
          if obj.class.model_settings[:name_with] != attribute || obj.send(attribute).nil?
            obj.send("#{attribute}=", value) if obj.respond_to?("#{attribute}=")
          end
        end
        obj
      end

      ##
      # Create an instance of +cls+ using provided +params+ to fill in attributes
      def instance_from_params(cls, params)
        n = cls.new
        populate_from_params(n, params)
      end

      ##
      # Serialize objects using a custom serializer that handles content negotiation
      # using the Accept header and "format" query string parameter
      # The method has two options parameters:
      #   +status (Fixnum)+: Status code to use in response
      #   +obj (Object)+: The object to serialize
      # Usage: +reply object+, +reply 201, object+
      def reply(*response)
        status = response.shift
        if !status.instance_of?(Fixnum)
          response.unshift status
          status = 200
        end

        obj = response.shift
        halt 404 if obj.nil?

        # Security check
        check_access(obj) if LinkedData.settings.enable_security

        LinkedData::Serializer.build_response(@env, status: status, ld_object: obj)
      end

      ##
      # Override the halt method provided by Sinatra to set the response appropriately
      def halt(*response)
        status, headers, obj = nil
        obj = response.first if response.length == 1
        if obj.instance_of?(Fixnum)
          # This is a status-only response
          status = obj
          obj = nil
        end
        status, obj = response.first, response.last if response.length == 2
        status, headers, obj = response.first, response[1], response.last if response.length == 3
        super(LinkedData::Serializer.build_response(@env, status: status, headers: headers, ld_object: obj))
      end

      ##
      # Create an error response body by wrapping a message in a common hash structure
      # Call by providing an error code and then message or just a message:
      #   +error "Error message"+
      #   +error 400, "Error message"+
      def error(*message)
        status = message.shift
        if !status.instance_of?(Fixnum)
          message.unshift status
          status = 500
        end
        halt status, { :errors => message, :status => status }
      end

      ##
      # Look for the includes parameter and provide a formatted list of attributes
      def includes_param
        if @params["include"]
          return @params["include"].split(",").map {|e| e.to_sym}
        end
        Array.new
      end

      ##
      # Look for the ontologies acronym and give back a formatted list of ontolody id uris
      # This can be called without passing an argument and it will use the values from the current request
      def ontologies_param(params = nil)
        params ||= @params
        if params["ontologies"]
          # Get list
          ontologies = params["ontologies"].split(",").map {|o| o.strip}
          # When they aren't URIs, make them URIs
          ontologies.map! {|o| o.start_with?("http://") ? o : ontology_uri_from_acronym(o)}
          if ontologies.include? nil
            error 404, "The ontologies parameter `[#{params["ontologies"]}]` includes non-existent acronyms. Notice that acronyms are case sensitive."
          end
          return ontologies
        end
        Array.new
      end

      def ontologies_param_to_acronyms(params = nil)
        ontResourceIds = ontologies_param(params)
        return ontResourceIds.map { |ontResourceId| ontResourceId.to_s.split('/')[-1]}
      end

      ##
      # Get semantic types parameter in the form [semanticTypes=T099,T085,T345]
      def semantic_types_param(params = nil)
        params ||= @params
        if params["semanticTypes"]
          semanticTypes = params["semanticTypes"].split(",").map {|o| o.strip}
          return semanticTypes
        end
        Array.new
      end

      ##
      # Given an acronym (BRO), get the ontology URI (http://data.bioontology.org/ontologies/BRO)
      # @param acronym [String] the ontology acronym
      def ontology_uri_from_acronym(acronym)
        ontology_uri_acronym_map[acronym]
      end

      ##
      # Given a URI (http://data.bioontology.org/ontologies/BRO), get the ontology acronym (BRO)
      # @param uri [String] the ontology uri
      def acronym_from_ontology_uri(uri)
        acronym_ontology_uri_map[uri.to_s]
      end

      ##
      # Given an ontology acronym returns the ontology model.
      # Replies 404 if the ontology does not exist
      # Replies 400 if the ontology does not have a parsed submission
      def ontology_from_acronym(acronym)
        ontology = LinkedData::Models::Ontology.find(acronym).first
        error(404, "Ontology with acronym `#{acronym}` not found") if ontology.nil?
        submission = ontology.latest_submission
        error(400, "No parsed submissions for ontology with acronym `#{acronym}`") if submission.nil?
        return ontology
      end

      ##
      # From user params, return the ontology models.
      # Replies 404 if the ontology does not exist
      # Replies 400 if the ontology does not have a parsed submission
      def ontology_objects_from_params(params = nil)
        ontologies = ontologies_param(params)
        ontology_objs = []
        ontologies.each do |ontology_id|
          ontology = LinkedData::Models::Ontology.find(uri_as_needed(ontology_id)).first
          error(404, "Ontology `#{ontology_id}` not found") if ontology.nil?
          submission = ontology.latest_submission
          error(400, "No parsed submissions for ontology with acronym `#{acronym}`") if submission.nil?
          ontology_objs << ontology
        end
        ontology_objs
      end

      def ontology_uri_acronym_map
        cached_map = naive_expiring_cache_read(__method__)
        return cached_map if cached_map
        map = {}
        LinkedData::Models::Ontology.where.include(:acronym).all.each {|o| map[o.acronym] = o.id.to_s}
        naive_expiring_cache_write(__method__, map)
        map
      end

      def acronym_ontology_uri_map
        cached_map = naive_expiring_cache_read(__method__)
        return cached_map if cached_map
        map = {}
        LinkedData::Models::Ontology.where.include(:acronym).all.each {|o| map[o.id.to_s] = o.acronym}
        naive_expiring_cache_write(__method__, map)
        map
      end

      ##
      # Create a URI if the id is a URI, otherwise return unmodified
      def uri_as_needed(id)
        id = replace_url_prefix(id)
        uri = RDF::URI.new(id)
        uri.valid? ? uri : id
      end

      ##
      # If the setting is enabled, replace the URL prefix with the proper id prefix
      # EX: http://stagedata.bioontology.org/ontologies/BRO would become http://data.bioontology.org/ontologies/BRO
      def replace_url_prefix(id)
        id = id.sub(LinkedData.settings.rest_url_prefix, LinkedData.settings.id_url_prefix) if LinkedData.settings.replace_url_prefix
        id
      end

      def retrieve_latest_submissions
        includes = OntologySubmission.goo_attrs_to_load(includes_param)
        submissions = OntologySubmission.where.include(includes).to_a

        # Figure out latest parsed submissions using all submissions
        latest_submissions = {}
        submissions.each do |sub|
          next unless sub.submissionStatus.parsed?
          latest_submissions[sub.ontology.acronym] ||= sub
          latest_submissions[sub.ontology.acronym] = sub if sub.submissionId > latest_submissions[sub.ontology.acronym].submissionId
        end
        return latest_submissions
      end

      def get_ontology_and_submission
        ont = Ontology.find(@params["ontology"])
              .include(:acronym)
              .include(submissions: [:submissionId, submissionStatus: [:code], ontology: [:acronym]])
                .first
        error(404, "Ontology '#{@params["ontology"]}' not found.") if ont.nil?
        submission = nil
        if @params.include? "ontology_submission_id"
          submission = ont.submission(@params[:ontology_submission_id])
          error 404, "You must provide an existing submission ID for the #{@params["acronym"]} ontology" if submission.nil?
        else
          submission = ont.latest_submission
        end
        error 404,  "Ontology #{@params["ontology"]} submission not found." if submission.nil?
        status = submission.submissionStatus
        if !status.parsed?
          error 404,  "Ontology #{@params["ontology"]} submission #{submission.submissionId} has not been parsed."
        end
        if submission.nil?
          error 404, "Ontology #{@params["acronym"]} does not have any submissions" if submission.nil?
        end
        return ont, submission
      end

      def current_user
        env["REMOTE_USER"]
      end

      private

      def naive_expiring_cache_write(key, object, timeout = 60)
        @naive_expiring_cache ||= {}
        @naive_expiring_cache[key] = {timeout: Time.now + timeout, object: object}
      end

      def naive_expiring_cache_read(key)
        return if @naive_expiring_cache.nil?
        object = @naive_expiring_cache[key]
        return if object.nil?
        return if Time.now > object[:timeout]
        return object[:object]
      end

    end
  end
end

helpers Sinatra::Helpers::ApplicationHelper
