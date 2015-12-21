require 'sinatra/base'
require 'multi_json'

module Sinatra
  module Helpers
    module SearchHelper
      ONTOLOGIES_PARAM = "ontologies"
      ONTOLOGY_PARAM = "subtree_ontology"
      EXACT_MATCH_PARAM = "require_exact_match"
      INCLUDE_VIEWS_PARAM = "also_include_views"
      REQUIRE_DEFINITIONS_PARAM = "require_definitions"
      INCLUDE_PROPERTIES_PARAM = "also_search_properties"
      SUBTREE_ID_PARAM = "subtree_root_id"
      ALSO_SEARCH_OBSOLETE_PARAM = "also_search_obsolete"
      ALSO_SEARCH_PROVISIONAL_PARAM = "also_search_provisional"
      SUGGEST_PARAM = "suggest" # NCBO-932
      # the three below are for NCBO-1512, NCBO-1513, NCBO-1515
      VALUESET_ROOTS_ONLY_PARAM = "valueset_roots_only"
      VALUESET_EXCLUDE_ROOTS_PARAM = "valueset_exclude_roots"
      ONTOLOGY_TYPES_PARAM = "ontology_types"

      ALSO_SEARCH_VIEWS = "also_search_views" # NCBO-961
      MATCH_HTML_PRE = "<em>"
      MATCH_HTML_POST = "</em>"
      MATCH_TYPE_PREFLABEL = "prefLabel"
      MATCH_TYPE_SYNONYM = "synonym"
      MATCH_TYPE_PROPERTY = "property"

      MATCH_TYPE_MAP = {
          "resource_id" => "id",
          MATCH_TYPE_PREFLABEL => MATCH_TYPE_PREFLABEL,
          "prefLabelExact" => MATCH_TYPE_PREFLABEL,
          "prefLabelSuggestEdge" => MATCH_TYPE_PREFLABEL,
          "prefLabelSuggestNgram" => MATCH_TYPE_PREFLABEL,
          MATCH_TYPE_SYNONYM => MATCH_TYPE_SYNONYM,
          "synonymExact" => MATCH_TYPE_SYNONYM,
          "synonymSuggestEdge" => MATCH_TYPE_SYNONYM,
          "synonymSuggestNgram" => MATCH_TYPE_SYNONYM,
          MATCH_TYPE_PROPERTY => MATCH_TYPE_PROPERTY,
          "notation" => "notation",
          "cui" => "cui",
          "semanticType" => "semanticType"
      }

      # list of fields that allow empty query text
      QUERYLESS_FIELDS_PARAMS = {
          "notation" => "notation",
          "cui" => "cui",
          "semantic_types" => "semanticType",
          "ontology_types" => "ontologyType"
      }

      QUERYLESS_FIELDS_STR = QUERYLESS_FIELDS_PARAMS.values.join(" ")

      def get_edismax_query(text, params={})
        validate_params_solr_population()

        # raise error if text is empty AND (none of the QUERYLESS_FIELDS_PARAMS has been passed
        # OR either an exact match OR suggest search is being executed)
        if (text.nil? || text.strip.empty?)
          if (!QUERYLESS_FIELDS_PARAMS.keys.any? {|k| params.key?(k)} ||
              params[EXACT_MATCH_PARAM] == "true" ||
              params[SUGGEST_PARAM] == "true")
            raise error 400, "The search query must be provided via /search?q=<query>[&page=<pagenum>&pagesize=<pagesize>]"
          else
            text = ''
          end
        end

        query = ""
        params["defType"] = "edismax"
        params["stopwords"] = "true"
        params["lowercaseOperators"] = "true"
        params["fl"] = "*,score"
        params[INCLUDE_VIEWS_PARAM] = params[ALSO_SEARCH_VIEWS] if params[ALSO_SEARCH_VIEWS]

        # highlighting is used to determine the field that got matched, NCBO-974
        params["hl"] = "on"
        params["hl.simple.pre"] = MATCH_HTML_PRE
        params["hl.simple.post"] = MATCH_HTML_POST

        # text.gsub!(/\*+$/, '')

        if (params[EXACT_MATCH_PARAM] == "true")
          query = "\"#{solr_escape(text)}\""
          params["qf"] = "resource_id^20 prefLabelExact^10 synonymExact #{QUERYLESS_FIELDS_STR}"
          params["hl.fl"] = "resource_id prefLabelExact synonymExact #{QUERYLESS_FIELDS_STR}"
        elsif (params[SUGGEST_PARAM] == "true" || text[-1] == '*')
          text.gsub!(/\*+$/, '')
          query = "\"#{solr_escape(text)}\""
          params["qt"] = "/suggest_ncbo"
          params["qf"] = "prefLabelExact^100 prefLabelSuggestEdge^50 synonymSuggestEdge^10 prefLabelSuggestNgram synonymSuggestNgram resource_id #{QUERYLESS_FIELDS_STR}"
          params["pf"] = "prefLabelSuggest^50"
          params["hl.fl"] = "prefLabelExact prefLabelSuggestEdge synonymSuggestEdge prefLabelSuggestNgram synonymSuggestNgram resource_id #{QUERYLESS_FIELDS_STR}"
        else
          if (text.strip.empty?)
            query = '*'
          else
            query = solr_escape(text)
          end

          params["qf"] = "resource_id^100 prefLabelExact^90 prefLabel^70 synonymExact^50 synonym^10 #{QUERYLESS_FIELDS_STR}"
          params["qf"] << " property" if params[INCLUDE_PROPERTIES_PARAM] == "true"
          params["hl.fl"] = "resource_id prefLabelExact prefLabel synonymExact synonym #{QUERYLESS_FIELDS_STR}"
          params["hl.fl"] = "#{params["hl.fl"]} property" if params[INCLUDE_PROPERTIES_PARAM] == "true"
        end

        params["ontologies"] = params["ontology_acronyms"].join(",") if params["ontology_acronyms"] && !params["ontology_acronyms"].empty?
        onts = restricted_ontologies(params)
        acronyms = restricted_ontologies_to_acronyms(params, onts)
        filter_query = get_quoted_field_query_param(acronyms, "OR", "submissionAcronym")

        subtree_ids = get_subtree_ids(params)
        subtree_ids_clause = (subtree_ids.nil? || subtree_ids.empty?) ? "" : get_quoted_field_query_param(subtree_ids, "OR", "resource_id")
        filter_query = "#{filter_query} AND #{subtree_ids_clause}" unless (subtree_ids_clause.empty?)

        # ontology types are required for CEDAR project to differentiate between ontologies and value set collections
        ontology_types = params[ONTOLOGY_TYPES_PARAM].nil? || params[ONTOLOGY_TYPES_PARAM].empty? ? [] : params[ONTOLOGY_TYPES_PARAM].split(",").map(&:strip)
        ontology_types_clause = ontology_types.empty? ? "" : get_quoted_field_query_param(ontology_types, "OR", "ontologyType")
        filter_query = "#{filter_query} AND #{ontology_types_clause}" unless (ontology_types_clause.empty?)

        # NCBO-1512, NCBO-1513, NCBO-1515 - CEDAR valueset requirements
        valueset_roots_only = params[VALUESET_ROOTS_ONLY_PARAM] || "false"
        valueset_exclude_roots = params[VALUESET_EXCLUDE_ROOTS_PARAM] || "false"

        if valueset_roots_only == "true" || valueset_exclude_roots == "true"
          valueset_root_ids = get_valueset_root_ids(onts, params)

          unless valueset_root_ids.empty?
            valueset_root_ids_clause = get_quoted_field_query_param(valueset_root_ids, "OR", "resource_id")
            valueset_root_ids_clause = valueset_exclude_roots == "true" ? "AND -#{valueset_root_ids_clause}" : "AND #{valueset_root_ids_clause}"
            filter_query = "#{filter_query} #{valueset_root_ids_clause}"
          end
        end

        filter_query << " AND definition:[* TO *]" if params[REQUIRE_DEFINITIONS_PARAM] == "true"

        # NCBO-688 - by default search only non-obsolete classes
        also_search_obsolete = params[ALSO_SEARCH_OBSOLETE_PARAM] || "false"
        filter_query << " AND obsolete:false" if also_search_obsolete != "true"

        # NCBO-1418 - enable optional include of provisional classes
        also_search_provisional = params[ALSO_SEARCH_PROVISIONAL_PARAM] || "false"
        filter_query << " AND -provisional:true" if also_search_provisional != "true"

        # NCBO-695 - ability to search on CUI and TUI
        cui = cui_param(params)
        cui_clause = (cui.nil? || cui.empty?) ? "" : get_quoted_field_query_param(cui, "OR", "cui")
        filter_query = "#{filter_query} AND #{cui_clause}" unless (cui_clause.empty?)

        # NCBO-695 - ability to search on CUI and TUI (Semantic Type)
        semantic_types = semantic_types_param(params)
        semantic_types_clause = (semantic_types.nil? || semantic_types.empty?) ? "" : get_quoted_field_query_param(semantic_types, "OR", "semanticType")
        filter_query = "#{filter_query} AND #{semantic_types_clause}" unless (semantic_types_clause.empty?)

        params["fq"] = filter_query
        params["q"] = query

        return query
      end

      def add_matched_fields(solr_response)
        match = MATCH_TYPE_PREFLABEL
        all_matches = {}

        solr_response["highlighting"].each do |key, matches|
          largest_count = 0

          matches.each do |match_type, val|
            count = val[0].scan(MATCH_HTML_PRE).count

            if count > largest_count
              largest_count = count
              match = MATCH_TYPE_MAP[match_type]
            end
          end
          all_matches[key] = match
        end

        solr_response["match_types"] = all_matches
      end

      # see https://github.com/rsolr/rsolr/issues/101
      # and https://github.com/projecthydra/active_fedora/commit/75b4afb248ee61d9edb56911b2ef51f30f1ce17f
      #
      def solr_escape(text)
        RSolr.solr_escape(text).gsub(/\s+/,"\\ ")
      end

      def get_subtree_ids(params)
        subtree_ids = nil
        subtree_root_id = params[SUBTREE_ID_PARAM]

        if subtree_root_id
          ontology = params[ONTOLOGY_PARAM].nil? ? nil : params[ONTOLOGY_PARAM].split(",")

          if (ontology.nil? || ontology.empty? || ontology.length > 1)
            raise error 400, "A subtree search requires a single ontology: /search?q=<query>&ontology=CNO&subtree_id=http%3a%2f%2fwww.w3.org%2f2004%2f02%2fskos%2fcore%23Concept"
          end

          ont, submission = get_ontology_and_submission
          params[:cls] = subtree_root_id
          params[ONTOLOGIES_PARAM] = params[ONTOLOGY_PARAM]

          cls = get_class(submission)
          subtree_ids = cls.descendants.map {|d| d.id.to_s}
          subtree_ids.push(subtree_root_id)
        end
        subtree_ids
      end

      def get_valueset_root_ids(onts, params)
        root_ids = []

        onts.each do |ont|
          next if ont.nil? || ont.ontologyType.nil? || !ont.ontologyType.value_set_collection?
          submission = ont.latest_submission(status: [:RDF])
          next if submission.nil?
          roots = submission.roots
          root_ids_ont = roots.map {|d| d.id.to_s}
          root_ids << root_ids_ont
        end
        root_ids.flatten
      end

      def get_tokenized_standard_query(text, params)
        words = text.split
        query = "("
        query << get_non_quoted_field_query_param(words, "prefLabel")
        query << " OR "
        query << get_non_quoted_field_query_param(words, "synonym")

        if params[INCLUDE_PROPERTIES_PARAM] == "true"
          query << " OR "
          query << get_non_quoted_field_query_param(words, "property")
        end
        query << ")"

        return query
      end

      def get_quoted_field_query_param(words, clause, fieldName="")
        query = fieldName.empty? ? "" : "#{fieldName}:"

        if (words.length > 1)
          query << "("
        end
        query << "\"#{words[0]}\""

        if (words.length > 1)
          words[1..-1].each do |word|
            query << " #{clause} \"#{word}\""
          end
        end

        if (words.length > 1)
          query << ")"
        end

        return query
      end

      def get_non_quoted_field_query_param(words, fieldName="")
        query = fieldName.empty? ? "" : "#{fieldName}:"
        query << words.join(" ")

        return query
      end

      def set_page_params(params={})
        pagenum, pagesize = page_params(params)
        params["page"] = pagenum
        params["pagesize"] = pagesize
        params.delete("q")
        params.delete("ontologies")

        unless params["start"]
          if pagenum <= 1
            params["start"] = 0
          else
            params["start"] = pagenum * pagesize - pagesize
          end
        end
        params["rows"] ||= pagesize
      end

      ##
      # Populate an array of classes. Returns a hash where the key is ontology_uri + class_id:
      # "http://data.bioontology.org/ontologies/ONThttp://ont.org/class1" => cls
      def populate_classes_from_search(classes, ontology_acronyms=nil)
        class_ids = []
        acronyms = (ontology_acronyms.nil?) ? [] : ontology_acronyms
        classes.each {|c| class_ids << c.id.to_s; acronyms << c.submission.ontology.acronym.to_s unless ontology_acronyms}
        acronyms.uniq!
        old_classes_hash = Hash[classes.map {|cls| [cls.submission.ontology.id.to_s + cls.id.to_s, cls]}]
        params = {"ontology_acronyms" => acronyms}

        # Use a fake phrase because we want a normal wildcard query, not the suggest.
        # Replace this with a wildcard below.
        get_edismax_query("avoid_search_mangling", params)
        params.delete("ontology_acronyms")
        params.delete("q")
        params["qf"] = "resource_id"
        params["fq"] << " AND #{get_quoted_field_query_param(class_ids, "OR", "resource_id")}"
        params["rows"] = 99999
        # Replace fake query with wildcard
        resp = LinkedData::Models::Class.search("*:*", params)

        classes_hash = {}
        resp["response"]["docs"].each do |doc|
          doc = doc.symbolize_keys
          resource_id = doc[:resource_id]
          doc.delete :resource_id
          doc[:id] = resource_id
          ontology_uri = doc[:ontologyId].first.sub(/\/submissions\/.*/, "")
          ont_uri_class_uri = ontology_uri + resource_id
          old_class = old_classes_hash[ont_uri_class_uri]
          next unless old_class
          doc[:submission] = old_class.submission
          doc[:properties] = MultiJson.load(doc.delete(:propertyRaw)) if include_param_contains?(:properties)
          instance = LinkedData::Models::Class.read_only(doc)
          classes_hash[ont_uri_class_uri] = instance
        end

        classes_hash
      end

    end
  end
end

helpers Sinatra::Helpers::SearchHelper
