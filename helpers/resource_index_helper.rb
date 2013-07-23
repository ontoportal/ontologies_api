require 'sinatra/base'
require 'redis'

require 'pry'

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
        # classes[acronym1|URI1]=classid1,classid2,classid3&classes[acronym2|URI2]=classid1,classid2
        classes = []
        if params.key?("classes")
          if not params["classes"].kind_of?(Hash)
            msg = "Malformed classes parameter. Try:\n"
            msg += "classes[ontAcronymA]=classA1,classA2,classA3&classes[ontAcronymB]=classB1,classB2\n"
            msg += "See #{LinkedData.settings.rest_url_prefix}documentation for details.\n"
            error 400, msg
          end
          class_hash = params["classes"]
          class_hash.each do |k,v|
            # Use 'k' as an ontology acronym or URI, translate it to an ontology virtual ID.
            ont_id = virtual_id_from_acronym(k)
            ont_id = virtual_id_from_uri(k) if ont_id.nil?
            msg = "Ontology #{k} cannot be found in the resource index. "
            msg += "See #{LinkedData.settings.rest_url_prefix}resource_index/ontologies for details."
            error 404, msg if ont_id.nil?
            # Use 'v' as a CSV list of concepts (class ID)
            v.split(',').each do |class_id|
              # Shorten id as necessary
              if class_id.start_with?("http://")
                ont_code = k.split("/").last
                ont_model = LinkedData::Models::Ontology.find(ont_code).first
                if ont_model.is_a? LinkedData::Models::Ontology
                  submission = ont_model.latest_submission
                  error 404, "Ontology #{k} (#{ont_code}) has no latest submission." if submission.nil?
                  submission.bring(hasOntologyLanguage: [:acronym])
                  ont_format = submission.hasOntologyLanguage.acronym
                end
                class_id = shorten_uri(class_id, ont_format)
              end
              # TODO: Determine whether class_id exists, throw 404 for invalid classes.
              classes.push("#{ont_id}/#{class_id}")
            end
          end
        end
        return classes
      end

      def get_options(params={})
        options = {}
        options[:debug] = true
        options[:request_timeout] = 600  # double the default of 300
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
        # Paging parameters (helper methods are in PaginationHelper)
        #
        # This gives you the page and page_size from the request with defaults if they don't exist
        page, page_size = page_params
        # Calculates offset (limit doesn't really get calculated, but just to be consistent we include it)
        offset, limit = offset_and_limit(page, page_size)
        options[:offset] = offset unless offset.nil?
        options[:limit] = limit unless limit.nil?
        #
        #* elements={element1,...,elementN}
        if params["elements"].is_a? String
          elements = params["elements"].split(',')
          options[:elementid] = elements unless elements.empty?
        end
        #
        #* resources={resource1,...,resourceN}
        if params["resources"].is_a? String
          resources = params["resources"].split(',')
          options[:resourceids] = resources unless resources.empty?
        end
        #
        #* ontologies={acronym1|URL1,acronym2|URL2,...,acronymN|URLn}
        if params['ontologies'].is_a? String
          ontologies = params['ontologies'].split(',')
          ontologies.map! {|acronym| virtual_id_from_acronym(acronym) }
          options[:ontologiesToExpand]       = ontologies unless ontologies.empty?
          options[:ontologiesToKeepInResult] = ontologies unless ontologies.empty?
        end
        #
        #* semantic_types={semType1,semType2,semType3}
        if params['semantic_types'].is_a? String
          semanticTypes = params['semantic_types'].split(',')
          options[:semanticTypes] = semanticTypes unless semanticTypes.empty?
        end
        #
        #* max_level={0..N}
        options[:levelMax] = params['max_level'] if params.key?('max_level')
        #
        #* mapping_types={automatic,manual}
        if params['mapping_types'].is_a? String
          mapping_types = params['mapping_types'].split(',')
          options[:mappingTypes] = mapping_types unless mapping_types.empty?
        end
        #
        #* exclude_numbers={true|false}
        options[:filterNumber] = params['exclude_numbers'] if params.key?('exclude_numbers')
        #
        #* minimum_match_length={0..N}
        options[:minTermSize] = params['minimum_match_length'] if params.key?('minimum_match_length')
        #
        #* include_synonyms={true|false}
        options[:withSynonyms] = params['include_synonyms'] if params.key?('include_synonyms')
        #
        #* include_offsets={true|false}
        # TODO: code this one!

        #
        #* mode={union|intersection}
        options[:mode] = params['mode'] if params.key?('mode')
        #
        # Stop words
        #
        #* exclude_words={word1,word2,word3}
        #* excluded_words_are_case_sensitive={true|false}
        exclude_words = [params['exclude_words']].compact
        options[:stopWords] = exclude_words
        options[:withDefaultStopWords] = false if not exclude_words.empty?
        case_sensitive = params['excluded_words_are_case_sensitive']
        options[:isStopWordsCaseSensitive] = case_sensitive unless case_sensitive.nil?

        return options
      end

      ##
      # Takes a URI and shortens it (takes off everything except the last fragment) according to NCBO rules.
      # Only OBO format has special processing.
      # The format can be obtained by doing ont.latest_submission.hasOntologyLanguage.acronym.to_s
      def shorten_uri(uri, ont_format = '')
        uri = uri.to_s
        if ont_format.eql?('OBO')
          if uri.start_with?('http://purl.org/obo/owl/')
            last_fragment = uri.split('/').last.split('#')
            prefix = last_fragment[0]
            mod_code = last_fragment[1]
          elsif uri.start_with?('http://purl.obolibrary.org/obo/')
            last_fragment = uri.split('/').last.split('_')
            prefix = last_fragment[0]
            mod_code = last_fragment[1]
          elsif uri.start_with?('http://www.cellcycleontology.org/ontology/owl/')
            last_fragment = uri.split('/').last.split('#')
            prefix = last_fragment[0]
            mod_code = last_fragment[1]
          elsif uri.start_with?('http://purl.bioontology.org/ontology/')
            last_fragment = uri.split('/')
            prefix = last_fragment[-2]
            mod_code = last_fragment[-1]
          end
          short_id = "#{prefix}:#{mod_code}"
        else
          # Everything other than OBO
          uri_parts = uri.split('/')
          short_id = uri_parts.last
          short_id = short_id.split('#').last if short_id.include?('#')
        end
        short_id
      end

      ##
      # Using the combination of the short_id (EX: "TM122581") and version_id (EX: "42389"),
      # this will do a Redis lookup and give you the full URI. The short_id is based on
      # what is produced by the `shorten_uri` method and should match Resource Index localConceptId output.
      # In fact, doing localConceptId.split("/") should give you the parameters for this method.
      # Population of redis data available here:
      # https://github.com/ncbo/ncbo_migration/blob/master/id_mappings_classes.rb
      def uri_from_short_id(version_id, short_id)
        acronym = acronym_from_version_id(version_id)
        uri = REDIS.get("old_to_new:uri_from_short_id:#{acronym}:#{short_id}")
        if uri.nil? && short_id.include?(':')
          try_again_id = short_id.split(':').last
          uri = REDIS.get("old_to_new:uri_from_short_id:#{acronym}:#{try_again_id}")
        end
        uri
      end

      ##
      # Given a virtual id, return the acronym (uses a Redis lookup)
      # Population of redis data available here:
      # https://github.com/ncbo/ncbo_migration/blob/master/id_mappings_ontology.rb
      # @param virtual_id [Integer] the ontology version ID
      def acronym_from_virtual_id(virtual_id)
        REDIS.get("old_to_new:acronym_from_virtual:#{virtual_id}")
      end

      ##
      # Given a version id, return the acronym (uses a Redis lookup)
      # Population of redis data available here:
      # https://github.com/ncbo/ncbo_migration/blob/master/id_mappings_ontology.rb
      # @param version_id [Integer] the ontology version ID
      def acronym_from_version_id(version_id)
        virtual = REDIS.get("old_to_new:virtual_from_version:#{version_id}")
        acronym_from_virtual_id(virtual)
      end

      ##
      # Given an acronym, return the virtual id (uses a Redis lookup)
      # Population of redis data available here:
      # https://github.com/ncbo/ncbo_migration/blob/master/id_mappings_ontology.rb
      # @param acronym [String] the ontology acronym
      def virtual_id_from_acronym(acronym)
        virtual_id = REDIS.get("old_to_new:virtual_from_acronym:#{acronym}")
        virtual_id.to_i unless virtual_id.nil?
        virtual_id
      end

      ##
      # Given a virtual id, return the ontology URI (uses a Redis lookup)
      # Population of redis data available here:
      # https://github.com/ncbo/ncbo_migration/blob/master/id_mappings_ontology.rb
      # @param virtual_id [Integer] the ontology virtual ID
      def ontology_uri_from_virtual_id(virtual_id)
        acronym = acronym_from_virtual_id(virtual_id)
        ontology_uri_from_acronym(acronym)
      end

      ##
      # Given an ontology id URI, get the virtual id (uses a Redis lookup)
      # Population of redis data available here:
      # https://github.com/ncbo/ncbo_migration/blob/master/id_mappings_ontology.rb
      # @param uri [String] ontology id in URI form
      def virtual_id_from_uri(uri)
        uri = replace_url_prefix(uri)
        acronym = acronym_from_ontology_uri(uri)
        virtual_id_from_acronym(acronym)
      end

    end
  end
end

helpers Sinatra::Helpers::ResourceIndexHelper
