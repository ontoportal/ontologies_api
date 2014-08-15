require 'ncbo_resource_index'

class ResourceIndexController < ApplicationController
  namespace "/resource_index" do

    get do
      ri = "resource_index"
      links = {
        resources: "#{LinkedData.settings.rest_url_prefix}#{ri}/resources",
        resource: "#{LinkedData.settings.rest_url_prefix}#{ri}/resources/{resource_id}",
        resource_documents: "#{LinkedData.settings.rest_url_prefix}#{ri}/resources/{resource_id}/documents/{document_id}",
        counts: "#{LinkedData.settings.rest_url_prefix}#{ri}/counts?classes[{ontology_id}]={class_id}",
        search: "#{LinkedData.settings.rest_url_prefix}#{ri}/{resource_id}/search?classes[{ontology_id}]={class_id}"
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

    # Return a specific resource
    get "/resources/:resource" do
      format_params(params)
      resource = ResourceIndex::Resource.find(params["resource"])
      error 404, "Could not find resource #{(params['resources'] || []).join(', ')}" unless resource
      reply resource
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
    get "/resources/:resources/documents/:document" do
      format_params(params)
      error 422, "You may only specify a single resource" if params["resources"].length > 1
      document = ResourceIndex::Document.find(params["resources"].first, params["document"])
      error 404, "No document with id #{params['document']} found" unless document
      reply document
    end

  end # namespace "/resource_index"
end # class ResourceIndexController
