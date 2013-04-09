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
        instance = LinkedData::Models::Class.read_only(resource_id, doc)
        docs.push(instance)
      end
      #need to return a Page object
      page = page_object(total_found, docs)
      reply 200, page
    end

    private

    def get_page_params(q, args={})
      args.delete "q"
      args.delete "page"
      args.delete "pagesize"
      raise error 400, "The search query must be provided via /search?q=<query>[&page=<pagenum>&pagesize=<pagesize>]" if q.nil? || q.strip.empty?
      pagenum, pagesize = page_params()
      args["start"] = pagenum
      args["rows"] = pagesize
      return args
    end
  end
end