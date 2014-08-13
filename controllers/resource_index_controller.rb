require 'ncbo_resource_index'

class ResourceIndexController < ApplicationController
  namespace "/resource_index" do

    get do
      path = request.path
      links = {
        resources: "#{path}/resources",
        resource: "#{path}/resources/{resource_id}",
        resource_documents: "#{path}/resources/{resource_id}/documents/{document_id}",
        counts: "#{path}/counts?classes[{ontology_id}]={class_id}",
        search: "#{path}/{resource_id}/search?classes[{ontology_id}]={class_id}"
      }
      reply ({links: links})
    end

    get '/counts' do
      format_params(params)
      classes = get_classes(params)
      error 404, "You must provide valid `classes` to retrieve resources" if classes.empty?
      reply classes.ri_counts(params["resources"])
    end

    # Return all resources
    get "/resources" do
      reply ResourceIndex::Resource.populated
    end

    # Return specific resources
    get "/resources/:resources" do
      format_params(params)
      resources = params["resources"].map {|res_id| ResourceIndex::Resource.find(res_id)}.compact.sort {|a,b| a.name.downcase <=> b.name.downcase}
      error 404, "Could not find resource #{params['resources'].join(', ')}" if resources.empty?
      reply resources
    end

    get '/resources/:resources/search' do
      format_params(params)
      classes = get_classes(params)
      error 404, "You must provide valid `classes` to retrieve resources" if classes.empty?
      error 422, "You may only specify a single resource" if params["resources"].length > 1
      resource = params["resources"].first
      reply classes.ri_docs_page(resource, params)
    end

    # Return a specific element from a specific resource
    get "/resources/:resources/documents/:documents" do
      format_params(params)
      result = ResourceIndex::Document.find(params["documents"], params["resources"], options)
      check404(result, "No element found.")
      element = massage_element(result, options[:elementDetails])
      reply element
    end

  end # namespace "/resource_index"
end # class ResourceIndexController
