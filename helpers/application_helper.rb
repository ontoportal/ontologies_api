require 'sinatra/base'
require 'date'

module Sinatra
  module Helpers
    module ApplicationHelper
      SERIALIZER = LinkedData::Serializer
      REDIS = Redis.new(host: LinkedData.settings.redis_host, port: LinkedData.settings.redis_port)

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
          attribute = attribute.to_sym
          attr_cls = obj.class.range(attribute)

          # Try to find dependent Goo objects, but only if the naming is not done via Proc
          # If naming is done via Proc, then try to lookup the Goo object using a hash of attributes
          if attr_cls && !attr_cls.name_with.is_a?(Proc)
            # Replace the initial value with the object, handling Arrays as appropriate
            if value.is_a?(Array)
              value = value.map {|e| attr_cls.find(e).include(attr_cls.attributes).first}
            else
              value = attr_cls.find(value).include(attr_cls.attributes).first
            end
          elsif attr_cls
            retreived_value = attr_cls.where(value.symbolize_keys).to_a
            if retreived_value.empty?
              # Create a new object and save if one didn't exist
              retreived_value = attr_cls.new(value.symbolize_keys)
              retreived_value.save
            end
            value = retreived_value
          elsif attribute == :created || attribute == :released
            # TODO: Remove this awful hack when obj.class.model_settings[:range][attribute] contains DateTime class
            value = DateTime.parse(value)
          elsif attribute == :homePage
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
        SERIALIZER.build_response(@env, status: status, ld_object: obj)
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
        super(SERIALIZER.build_response(@env, status: status, headers: headers, ld_object: obj))
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
          # Extra safe, do a Goo lookup for any remaining
          ontologies.map! do |o|
            if o.to_s.start_with?("http://")
              o
            else
              ont = Ontology.find(o).first
              if ont.nil?
                nil
              else
                ont.id.to_s
              end
            end
          end
          if ontologies.include? nil
            error 404, "The ontologies parameter `[#{params["ontologies"]}]` includes non-existent acronyms. Notice that acronyms are case sensitive."
          end
          ontologies.compact!
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
      # Given an acronym, get the ontology URI (http://data.bioontology.org/ontologies/BRO)
      # @param acronym [String] the ontology acronym
      def ontology_uri_from_acronym(acronym)
        return REDIS.get("ont_id:uri:#{acronym}") || acronym
      end

    end
  end
end

helpers Sinatra::Helpers::ApplicationHelper
