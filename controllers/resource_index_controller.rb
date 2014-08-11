require 'resource_index'

class ResourceIndexController < ApplicationController
  TWENTYFOUR_HOURS  = 60 * 60 * 24

  namespace "/resource_index" do

    get do
    end

    get '/counts' do
      format_params(params)
      classes = get_classes(params)
      error 404, "You must provide valid `classes` to retrieve resources" if classes.empty?
      reply classes.ri_counts(params["resources"])
    end

    # Return all resources
    get "/resources" do
      # expires TWENTYFOUR_HOURS, :public
      reply RI::Resource.populated
    end

    # Return specific resources
    get "/resources/:resources" do
      format_params(params)
      resources = params["resources"].map {|res_id| RI::Resource.find(res_id)}.compact.sort {|a,b| a.name.downcase <=> b.name.downcase}
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
    get "/resources/:resources/elements/:elements" do
      format_params(params)
      result = NCBO::ResourceIndex.element(params["elements"], params["resources"], options)
      check404(result, "No element found.")
      element = massage_element(result, options[:elementDetails])
      reply element
    end

  end # namespace "/resource_index"
end # class ResourceIndexController
