class SearchController < ApplicationController
  namespace "/search" do
    ONTOLOGIES_PARAM = "ontologies"
    EXACT_MATCH_PARAM = "exactMatch"
    INCLUDE_VIEWS_PARAM = "includeViews"
    REQUIRE_DEFINITIONS_PARAM = "requireDefinitions"

    # execute a search query
    get do
      q = params["q"]
      globalParams = @params.dup
      query = get_query(q, globalParams)
      params = get_params(globalParams)
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
        instance = LinkedData::Models::Class.read_only(doc)
        docs.push(instance)
      end
      #need to return a Page object
      page = page_object(docs, total_found)
      reply 200, page
    end

    private

    def get_query(q, args={})
      raise error 400, "The search query must be provided via /search?q=<query>[&page=<pagenum>&pagesize=<pagesize>]" if q.nil? || q.strip.empty?
      query = ""
      acronyms = []

      if args[EXACT_MATCH_PARAM] == "true"
        query = "prefLabelExact:\"#{q}\""
      else
        query = get_tokenized_query(q)
      end

      if !args[ONTOLOGIES_PARAM]
        if args[INCLUDE_VIEWS_PARAM] == "true"
          onts = Ontology.where.include(:acronym).to_a
        else
          onts = Ontology.where.filter(Goo::Filter.new(:viewOf).unbound).include([:acronym]).to_a
        end
        acronyms = onts.map {|o| o.acronym}
      else
        acronyms = params[ONTOLOGIES_PARAM].split(",").map {|o| o.strip}
      end

      query << " AND "
      query << get_single_field_query_param(acronyms, "submissionAcronym", "OR")

      if args[REQUIRE_DEFINITIONS_PARAM] == "true"
        query << " AND definition:[* TO *]"
      end

      return query
    end

    def get_tokenized_query(text)
      words = text.split
      query = "("
      query << get_single_field_query_param(words, "prefLabel", "AND")
      query << " OR "
      query << get_single_field_query_param(words, "synonym", "AND")
      query << ")"
      return query
    end

    def get_single_field_query_param(words, fieldName, clause)
      query = "#{fieldName}:"

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

    def get_params(args={})
      args.delete "q"
      args.delete "page"
      args.delete "pagesize"
      pagenum, pagesize = page_params()

      if pagenum <= 1
        args["start"] = 0
      else
        args["start"] = pagenum * pagesize - pagesize
      end
      args["rows"] = pagesize
      return args
    end
  end
end