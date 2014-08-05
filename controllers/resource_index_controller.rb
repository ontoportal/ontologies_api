require 'resource_index'

class ResourceIndexController < ApplicationController
  TWENTYFOUR_HOURS  = 60 * 60 * 24

  namespace "/resource_index" do

    get '/search' do
      options = get_options(params)
      classes = get_classes(params)
      error 404, "You must provide valid `classes` to retrieve resources" if classes.empty?

      search_array = massage_search(result, options)
      page = page_object(search_array)
      reply page
    end

    # Return all resources
    get "/resources" do
      # expires TWENTYFOUR_HOURS, :public
      options = get_options(params)
      result = NCBO::ResourceIndex.resources(options)
      check404(result, "No resources found.")
      reply massage_resources(result)
    end

    # Return specific resources
    get "/resources/:resources" do
      options = get_options(params)
      result = NCBO::ResourceIndex.resources_hash(options)
      check404(result, "No resources found.")
      resources_filtered = []
      options[:resourceids].each do |r|
        rid = r.downcase.to_sym
        resources_filtered.push result[rid] if result.keys.include? rid
      end
      reply massage_resources(resources_filtered)
    end

    # Return a specific element from a specific resource
    get "/resources/:resources/elements/:elements" do
      options = get_options(params)
      result = NCBO::ResourceIndex.element(params["elements"], params["resources"], options)
      check404(result, "No element found.")
      element = massage_element(result, options[:elementDetails])
      reply element
    end

  end # namespace "/resource_index"
end # class ResourceIndexController
