require 'sinatra/base'
require 'redis'

#  @options[:resource_index_location]  = "http://rest.bioontology.org/resource_index/"
#  @options[:filterNumber]             = true
#  @options[:isStopWordsCaseSensitive] = false
#  @options[:isVirtualOntologyId]      = true
#  @options[:levelMax]                 = 0
#  @options[:longestOnly]              = false
#  @options[:ontologiesToExpand]       = []
#  @options[:ontologiesToKeepInResult] = []
#  @options[:mappingTypes]             = []
#  @options[:minTermSize]              = 3
#  @options[:scored]                   = true
#  @options[:semanticTypes]            = []
#  @options[:stopWords]                = []
#  @options[:wholeWordOnly]            = true
#  @options[:withDefaultStopWords]     = true
#  @options[:withSynonyms]             = true
#  @options[:conceptids]               = []
#  @options[:mode]                     = :union
#  @options[:elementid]                = []
#  @options[:resourceids]              = []
#  @options[:elementDetails]           = false
#  @options[:withContext]              = true
#  @options[:offset]                   = 0
#  @options[:limit]                    = 10
#  @options[:format]                   = :xml
#  @options[:counts]                   = false
#  @options[:request_timeout]          = 300

module Sinatra
  module Helpers
    module ResourceIndexHelper
      REDIS = Redis.new(host: LinkedData.settings.redis_host, port: LinkedData.settings.redis_port)

      def get_classes(params)
        # Assume request signature of the form:
        # classes[acronym1][classid1,classid2,classid3]&classes[acronym2][classid1,classid2]
        classes = []
        if params.key?("classes")
          class_hash = params["classes"]
          class_hash.each do |k,v|
            # Use 'k' as an ontology acronym, translate it to an ontology virtual ID.
            ont_id = virtual_id_from_acronym(k)
            next if ont_id == nil  # TODO: raise an exception?
            # Use 'v' as a CSV list of concepts (class ID)
            v.split(',').each do |class_id|
              classes.push("#{ont_id}/#{class_id}")
            end
          end
        end
        return classes
      end

      def get_options(params={})
        options = {}
        # The ENV["REMOTE_USER"] object (this is a variable that stores a per-request instance of
        # a LinkedData::Models::User object based on the API Key used in the request). The apikey
        # is one of the attributes on the user object.
        user = ENV["REMOTE_USER"]
        if user.nil?
          # Fallback to APIKEY from config/env/dev
          options[:apikey] = LinkedData.settings.apikey
        else
          options[:apikey] = user.apikey
        end
        #
        # Generic parameters that can apply to any endpoint.
        #
        #* elements={element1,element2}
        element = [params["elements"]].compact
        options[:elementid] = element unless element.nil? || element.empty?
        #
        #* resources={resource1,resource2}
        resource = [params["resources"]].compact
        options[:resourceids] = resource unless resource.nil? || resource.empty?
        #
        #* ontologies={acronym1,acronym2,acronym3}
        ontologies = [params["ontologies"]].compact
        ontologies.map! {|acronym| virtual_id_from_acronym(acronym) }
        options[:ontologiesToExpand]       = ontologies
        options[:ontologiesToKeepInResult] = ontologies
        #
        #* semantic_types={semType1,semType2,semType3}
        semanticTypes = [params["semantic_types"]].compact
        options[:semanticTypes] = semanticTypes unless semanticTypes.nil? || semanticTypes.empty?
        #
        #* max_level={0..N}
        options[:levelMax] = params["max_level"] if params.key?("max_level")
        #
        #* mapping_types={automatic,manual}
        mapping_types = [params["mapping_types"]].compact
        options[:mappingTypes] = mapping_types unless mapping_types.empty?
        #
        #* exclude_numbers={true|false}
        options[:filterNumber] = params["exclude_numbers"] if params.key?("exclude_numbers")
        #
        #* minimum_match_length={0..N}
        options[:minTermSize] = params["minimum_match_length"] if params.key?("minimum_match_length")
        #
        #* include_synonyms={true|false}
        options[:withSynonyms] = params["include_synonyms"] if params.key?("include_synonyms")
        #
        #* include_offsets={true|false}
        # TODO: code this one!

        #
        #* mode={union|intersection}
        options[:mode] = params["mode"] if params.key?("mode")
        #
        # Stop words
        #
        #* exclude_words={word1,word2,word3}
        #* excluded_words_are_case_sensitive={true|false}
        exclude_words = [params["exclude_words"]].compact
        options[:stopWords] = exclude_words
        options[:withDefaultStopWords] = false if not exclude_words.empty?
        case_sensitive = params["excluded_words_are_case_sensitive"]
        options[:isStopWordsCaseSensitive] = case_sensitive unless case_sensitive.nil?

        return options
      end

      ##
      # Takes a URI and shortens it (takes off everything except the last fragment) according to NCBO rules.
      # Only OBO format has special processing.
      # The format can be obtained by doing ont.latest_submission.hasOntologyLanguage.acronym.to_s
      def shorten_uri(uri, ont_format = "")
        uri = uri.to_s
        if ont_format.eql?("OBO")
          if uri.start_with?("http://purl.org/obo/owl/")
            last_fragment = uri.split("/").last.split("#")
            prefix = last_fragment[0]
            mod_code = last_fragment[1]
          elsif uri.start_with?("http://purl.obolibrary.org/obo/")
            last_fragment = uri.split("/").last.split("_")
            prefix = last_fragment[0]
            mod_code = last_fragment[1]
          elsif uri.start_with?("http://www.cellcycleontology.org/ontology/owl/")
            last_fragment = uri.split("/").last.split("#")
            prefix = last_fragment[0]
            mod_code = last_fragment[1]
          elsif uri.start_with?("http://purl.bioontology.org/ontology/")
            last_fragment = uri.split("/")
            prefix = last_fragment[-2]
            mod_code = last_fragment[-1]
          end
          short_id = "#{prefix}:#{mod_code}"
        else
          # Everything other than OBO
          uri_parts = uri.split("/")
          short_id = uri_parts.last
          short_id = short_id.split("#").last if short_id.include?("#")
        end
        short_id
      end

      ##
      # Using the combination of the short_id (EX: "TM122581") and version_id (EX: "42389"),
      # this will do a Redis lookup and give you the full URI. The short_id is based on
      # what is produced by the `shorten_uri` method and should match Resource Index localConceptId output.
      # In fact, doing localConceptId.split("/") should give you the parameters for this method.
      def uri_from_short_id(version_id, short_id)
        uri = REDIS.get("ri:#{version_id}:#{short_id}")
        if uri.nil? && short_id.include?(":")
          try_again_id = short_id.split(":").last
          uri = REDIS.get("ri:#{version_id}:#{try_again_id}")
        end
        uri
      end

      ##
      # Given a version id, return the acronym (uses a Redis lookup)
      def acronym_from_version_id(version_id)
        REDIS.hmget("ri:#{version_id}", "acronym").first
      end

      ##
      # Given a virtual id, return the acronym (uses a Redis lookup)
      def acronym_from_virtual_id(virtual_id)
        REDIS.hmget("ri:#{virtual_id}", "acronym").first
      end

      ##
      # Given an acronym, return the virtual id (uses a Redis lookup)
      def virtual_id_from_acronym(acronym)
        uri = ontology_uri_from_acronym(acronym)
        return virtual_id_from_uri(uri)
      end

      # Given an acronym, get the ontology id URI (http://data.bioontology.org/ontologies/BRO)
      def ontology_uri_from_acronym(acronym)
        REDIS.get("ont_id:uri:#{acronym}")
      end

      ##
      # Given an ontology id URI, get the virtual id
      def virtual_id_from_uri(uri)
        virtual_id = REDIS.get("ont_id:virtual:#{uri}")
        virtual_id = virtual_id.to_i unless virtual_id.nil?
        virtual_id
      end

    end
  end
end

helpers Sinatra::Helpers::ResourceIndexHelper
