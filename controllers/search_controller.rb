class SearchController < ApplicationController
  namespace "/search" do

    # execute a search query
    get do
      q = params["q"]
      globalParams = @params.dup
      query = get_query(q, globalParams)
      params = get_params(globalParams)
      docs = Array.new

      puts query
      puts
      puts params


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
      ontParam = ""

      if args["exactMatch"] == "true"
        query = "prefLabelExact:\"#{q}\""
      else
        query = "(prefLabel:#{q} OR synonym:#{q})"
      end
      query << " AND submissionAcronym:"

      if !args["ontologies"]
        if args["includeViews"] == "true"
          onts = Ontology.where.include(:acronym).to_a
        else
          onts = Ontology.where.filter(Goo::Filter.new(:viewOf).unbound).include([:acronym]).to_a
        end
        acronyms = onts.map {|o| o.acronym}
      else
        acronyms = params["ontologies"].split(",").map {|o| o.strip}
      end

      if (acronyms.length == 1)
        ontParam << "\"#{acronyms[0]}\""
      elsif (acronyms.length > 1)
        ontParam << "(\"#{acronyms[0]}\""
        acronyms[1..-1].each do |ont|
          ontParam << " OR \"#{ont}\""
        end
        ontParam << ")"
      end
      query << ontParam

      if args["onlyDefinitions"] == "true"
        query << " AND definition:[* TO *]"
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