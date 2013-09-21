require 'sinatra/base'
require 'ncbo_resolver'

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
      NCBO::Resolver.configure(redis_host: OntologiesAPI.settings.resolver_redis_host,
                               redis_port: OntologiesAPI.settings.resolver_redis_port)

      # Old REST service used for resolving class URIs into short IDs.
      REST_URL = 'http://rest.bioontology.org/bioportal'

      def classes_error(params)
        msg = "Malformed parameters. Try:\n"
        msg += "classes[ontAcronymA]=classA1,classA2,classA3&classes[ontAcronymB]=classB1,classB2\n"
        msg += "See #{LinkedData.settings.rest_url_prefix}documentation for details.\n\n"
        msg += "Parameters:  #{params.to_s}"
        error 400, msg
      end

      def get_classes(params)
        # Assume request signature of the form:
        # classes[acronym1|URI1]=classid1,classid2,classid3&classes[acronym2|URI2]=classid1,classid2
        classes = []
        if params.key?("classes")
          classes_error(params) if not params["classes"].kind_of? Hash
          class_hash = params["classes"]
          class_hash.each do |k,v|
            # Use 'k' as an ontology acronym or URI, translate it to an ontology virtual ID.
            ont_id = virtual_id_from_acronym(k)
            ont_id = virtual_id_from_uri(k) if ont_id.nil?
            msg = "Ontology #{k} cannot be found in the resource index. "
            msg += "See #{LinkedData.settings.rest_url_prefix}resource_index/ontologies for details."
            error 404, msg if ont_id.nil?
            classes_error(params) if not v.kind_of? String
            # Use 'v' as a CSV list of concepts (class ID)
            v.split(',').each do |class_id|
              # Shorten id, if necessary
              if class_id.start_with?("http://")
                class_id = short_id_from_uri(class_id, ont_id)
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
        options[:apikey] = get_apikey
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
      # Takes a URI and shortens it using a lookup from redis (populated using ncbo_resolver)
      def short_id_from_uri(cls_uri, ont_virtual_id)
        acronym = NCBO::Resolver::Ontologies.acronym_from_id(ont_virtual_id)
        NCBO::Resolver::Classes.short_id_from_uri(acronym, cls_uri)
      end

      ##
      # Using the combination of the short_id (EX: "TM122581") and version_id (EX: "42389") OR acronym,
      # this will do a Redis lookup and give you the full URI. The short_id is based on
      # what is produced by the `short_id_from_uri` method and should match Resource Index localConceptId output.
      # In fact, doing localConceptId.split("/") should give you the parameters for this method.
      # Population of redis data available here:
      # https://github.com/ncbo/ncbo_resolver
      def uri_from_short_id(id, short_id)
        if id.to_i > 0
          acronym = NCBO::Resolver::Ontologies.acronym_from_id(id)
        else
          acronym = id
        end
        NCBO::Resolver::Classes.uri_from_short_id(acronym, short_id)
      end

      ##
      # Given a virtual id, return the acronym (uses a Redis lookup)
      # Population of redis data available here:
      # https://github.com/ncbo/ncbo_resolver
      # @param virtual_id [Integer] the ontology version ID
      def acronym_from_virtual_id(virtual_id)
        NCBO::Resolver::Ontologies.acronym_from_virtual_id(virtual_id)
      end

      ##
      # Given a version id, return the acronym (uses a Redis lookup)
      # Population of redis data available here:
      # https://github.com/ncbo/ncbo_resolver
      # @param version_id [Integer] the ontology version ID
      def acronym_from_version_id(version_id)
        NCBO::Resolver::Ontologies.acronym_from_version_id(version_id)
      end

      ##
      # Given an acronym, return the virtual id (uses a Redis lookup)
      # Population of redis data available here:
      # https://github.com/ncbo/ncbo_resolver
      # @param acronym [String] the ontology acronym
      def virtual_id_from_acronym(acronym)
        NCBO::Resolver::Ontologies.virtual_id_from_acronym(acronym)
      end

      ##
      # Given a virtual id, return the ontology URI (uses a Redis lookup)
      # Population of redis data available here:
      # https://github.com/ncbo/ncbo_resolver
      # @param virtual_id [Integer] the ontology virtual ID
      def ontology_uri_from_virtual_id(virtual_id)
        acronym = acronym_from_virtual_id(virtual_id)
        ontology_uri_from_acronym(acronym)
      end

      ##
      # Given an ontology id URI, get the virtual id (uses a Redis lookup)
      # Population of redis data available here:
      # https://github.com/ncbo/ncbo_resolver
      # @param uri [String] ontology id in URI form
      def virtual_id_from_uri(uri)
        uri = replace_url_prefix(uri) rescue binding.pry
        acronym = acronym_from_ontology_uri(uri)
        virtual_id_from_acronym(acronym)
      end

      def get_apikey()
        user = current_user
        if user.nil?
          # Fallback to APIKEY from config/env/dev
          apikey = LinkedData.settings.apikey
        else
          apikey = user.apikey
        end
        return apikey
      end

    end
  end
end

helpers Sinatra::Helpers::ResourceIndexHelper
