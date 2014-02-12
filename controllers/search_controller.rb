require 'cgi'

class SearchController < ApplicationController
  namespace "/search" do
    # execute a search query
    get do
      process_search()
    end

    post do
      process_search()
    end

    private

    def process_search(params=nil)
      params ||= @params
      text = params["q"]

      query = get_edismax_query(text, params)
      #puts "Edismax query: #{query}, params: #{params}"
      set_page_params(params)

      docs = Array.new
      resp = LinkedData::Models::Class.search(query, params)
      total_found = resp["response"]["numFound"]

      resp["response"]["docs"].each do |doc|
        doc = doc.symbolize_keys
        resource_id = doc[:resource_id]
        doc.delete :resource_id
        doc[:id] = resource_id
        # TODO: The `rescue next` on the following line shouldn't be here
        # However, at some point we didn't store the ontologyId in the index
        # and these records haven't been cleared out so this is getting skipped
        ontology_uri = doc[:ontologyId].first.sub(/\/submissions\/.*/, "") rescue next
        ontology = LinkedData::Models::Ontology.read_only(id: ontology_uri, acronym: doc[:submissionAcronym])
        submission = LinkedData::Models::OntologySubmission.read_only(id: doc[:ontologyId], ontology: ontology)
        doc[:submission] = submission
        doc[:ontology_rank] = LinkedData::OntologiesAPI.settings.ontology_rank[doc[:submissionAcronym]] || 0
        instance = LinkedData::Models::Class.read_only(doc)
        docs.push(instance)
      end

      docs.sort! {|a, b| [b[:score], b[:ontology_rank], ] <=> [a[:score], a[:ontology_rank]]}

      #need to return a Page object
      page = page_object(docs, total_found)

      reply 200, page
    end

    def get_edismax_query(text, params={})
      raise error 400, "The search query must be provided via /search?q=<query>[&page=<pagenum>&pagesize=<pagesize>]" if text.nil? || text.strip.empty?
      query = ""
      params["defType"] = "edismax"
      params["stopwords"] = "true"
      params["lowercaseOperators"] = "true"
      params["fl"] = "*,score"

      if (params[EXACT_MATCH_PARAM] == "true")
        query = "\"#{RSolr.escape(text)}\""
        params["qf"] = "prefLabelExact"
      elsif (text[-1] == '*')
        text = text[0..-2]
        query = "\"#{RSolr.escape(text)}\""
        params["qt"] = "/suggest"
        params["qf"] = "prefLabelSuggestEdge^50 synonymSuggestEdge"
        params["pf"] = "prefLabelSuggest^50"
        params["sort"] = "score desc, prefLabelExact asc"
      else
        query = RSolr.escape(text)
        params["qf"] = "prefLabelExact^100 synonymExact^80 prefLabel^50 synonym^10 notation resource_id"
        params["qf"] << " property" if params[INCLUDE_PROPERTIES_PARAM] == "true"
      end

      subtree_ids = get_subtree_ids(params)
      acronyms = restricted_ontologies_to_acronyms(params)
      filter_query = get_quoted_field_query_param(acronyms, "OR", "submissionAcronym")
      ids_clause = (subtree_ids.nil? || subtree_ids.empty?)? "" : get_quoted_field_query_param(subtree_ids, "OR", "resource_id")

      if (!ids_clause.empty?)
        filter_query = "#{filter_query} AND #{ids_clause}"
      end

      if params[REQUIRE_DEFINITIONS_PARAM] == "true"
        filter_query << " AND definition:[* TO *]"
      end

      if ["true", "false"].include? params[OBSOLETE_PARAM]
        filter_query << " AND obsolete:#{params[OBSOLETE_PARAM]}"
      end

      params["fq"] = filter_query
      params["q"] = query

      return query
    end

    def escape_text(text)
      text.gsub(/([:\[\]\{\}])/, '\\\\\1')
    end

    def get_subtree_ids(params)
      subtree_ids = nil

      if (params[SUBTREE_ID_PARAM])
        ontology = params[ONTOLOGY_PARAM].split(",")

        if (ontology.nil? || ontology.empty? || ontology.length > 1)
          raise error 400, "A subtree search requires a single ontology: /search?q=<query>&ontology=CNO&subtree_id=http%3a%2f%2fwww.w3.org%2f2004%2f02%2fskos%2fcore%23Concept"
        end

        ont, submission = get_ontology_and_submission
        params[:cls] = params[SUBTREE_ID_PARAM]
        params[ONTOLOGIES_PARAM] = params[ONTOLOGY_PARAM]

        cls = get_class(submission, load_attrs={descendants: true})
        subtree_ids = cls.descendants.map {|d| d.id.to_s}
        subtree_ids.push(params[SUBTREE_ID_PARAM])
      end

      return subtree_ids
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
  end
end
