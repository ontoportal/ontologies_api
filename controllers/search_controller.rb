class SearchController < ApplicationController
  namespace "/search" do

    # execute a search query
    get do
      q = params["q"]
      page_params = get_page_params(q, @params.dup)
      docs = Array.new
      resp = LinkedData::Models::Class.search(q, page_params)
      total_found = resp["response"]["numFound"]

      resp["response"]["docs"].each do |doc|
        resource_id = doc["resource_id"]
        doc.delete "resource_id"
        doc[:id] = resource_id
        ontology_uri = doc["ontologyId"].first.sub(/\/submissions\/.*/, "")
        ontology = LinkedData::Models::Ontology.read_only(id: ontology_uri, acronym: doc["submissionAcronym"])
        submission = LinkedData::Models::OntologySubmission.read_only(id: doc["ontologyId"], ontology: ontology)
        doc[:submission] = submission
        instance = LinkedData::Models::Class.read_only(doc)
        docs.push(instance)
      end
      #need to return a Page object
      page = page_object(docs, total_found)
      reply 200, page
    end

    private

    def get_page_params(q, args={})
      args.delete "q"
      args.delete "page"
      args.delete "pagesize"
      raise error 400, "The search query must be provided via /search?q=<query>[&page=<pagenum>&pagesize=<pagesize>]" if q.nil? || q.strip.empty?
      pagenum, pagesize = page_params()


      if pagenum <= 1
        args["start"] = 0


      else
        args["start"] = 0
      end
      args["rows"] = pagesize
      return args
    end
  end
end