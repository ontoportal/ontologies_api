class SearchController < ApplicationController
  namespace "/search" do
    ONTOLOGIES_PARAM = "ontologies"
    EXACT_MATCH_PARAM = "exact_match"
    INCLUDE_VIEWS_PARAM = "include_views"
    REQUIRE_DEFINITIONS_PARAM = "require_definition"
    INCLUDE_PROPERTIES_PARAM = "include_properties"

    # execute a search query
    get do
      process_search()
    end

    post do
      process_search()
    end

    private

    def process_search(params = nil)
      params ||= @params
      q = params["q"]
      globalParams = @params.dup
      query = get_query(q, globalParams)




      puts query




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

        #TODO: this is a termporary sort until we find a better solution for wildcard queries
        docs.sort! {|a, b| a[:prefLabel].downcase <=> b[:prefLabel].downcase} if (q[-1] == '*')
      end
      #need to return a Page object
      page = page_object(docs, total_found)
      reply 200, page
    end

    def get_query(q, args={})
      raise error 400, "The search query must be provided via /search?q=<query>[&page=<pagenum>&pagesize=<pagesize>]" if q.nil? || q.strip.empty?
      query = ""
      onts = nil

      if (args[EXACT_MATCH_PARAM] == "true")
        query = "prefLabelExact:\"#{q}\""
      elsif (q[-1] == '*')
        q.gsub!(/\s+/, '\ ')
        query = "prefLabelExact:#{q}"
        args["pagesize"] = 500
      else
        query = get_tokenized_query(q, args)
      end

      if args[ONTOLOGIES_PARAM]
        onts = ontology_objects_from_params()
        Ontology.where.models(onts).include(*Ontology.access_control_settings[:access_control_load]).all
      else
        if args[INCLUDE_VIEWS_PARAM] == "true"
          onts = Ontology.where.include(Ontology.goo_attrs_to_load(includes_param)).to_a
        else
          onts = Ontology.where.filter(Goo::Filter.new(:viewOf).unbound).include(Ontology.goo_attrs_to_load(includes_param)).to_a
        end
      end
      #onts = filter_access(onts)
      acronyms = onts.map {|o| o.acronym}

      if acronyms && !acronyms.empty?
        query << " AND "
        query << get_quoted_field_query_param(acronyms, "submissionAcronym", "OR")
      end

      if args[REQUIRE_DEFINITIONS_PARAM] == "true"
        query << " AND definition:[* TO *]"
      end

      return query
    end

    def get_tokenized_query(text, args)
      words = text.split
      query = "("
      query << get_non_quoted_field_query_param(words, "prefLabel")
      query << " OR "
      query << get_non_quoted_field_query_param(words, "synonym")

      if args[INCLUDE_PROPERTIES_PARAM] == "true"
        query << " OR "
        query << get_non_quoted_field_query_param(words, "property")
      end

      query << ")"
      return query
    end

    def get_quoted_field_query_param(words, fieldName, clause)
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

    def get_non_quoted_field_query_param(words, fieldName)
      query = "#{fieldName}:"
      query << words.join(" ")
      return query
    end

    def get_params(args={})
      pagenum, pagesize = page_params(args)
      args.delete "q"
      args.delete "page"
      args.delete "pagesize"
      args.delete "ontologies"

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