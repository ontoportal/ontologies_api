
require 'ncbo_resource_index'

class ResourceIndexController < ApplicationController

  # Note: methods from resource_index_helper.rb :
  #  -  get_options(params)
  #  -  get_ontology_virtual_id(ontology_acronym)

  namespace "/resource_index" do

    get '/search' do
      options = get_options(params)
      classes = get_classes(params)
      if classes.empty?
        #
        # TODO: reply with syntax error message?
        #
      else
        result = NCBO::ResourceIndex.find_by_concept(classes, options)
        # TODO: massage the result format
        reply result
      end
    end

    get '/ranked_elements' do
      options = get_options(params)
      classes = get_classes(params)
      if classes.empty?
        #
        # TODO: reply with syntax error message?
        #
      else
        result = NCBO::ResourceIndex.ranked_elements(classes, options)
        result.resources.each do |r|
          r[:elements] = massage_elements(r[:elements])
        end
        reply result
      end
    end

    # Return all resources
    get "/resources" do
      options = get_options(params)
      result = NCBO::ResourceIndex.resources(options)
      reply massage_resources(result)
    end

    # Return a specific resource
    get "/resources/:resource_id" do
      options = get_options(params)
      result = NCBO::ResourceIndex.resources(options)
      reply massage_resources(result)
    end

    # Return a specific element from a specific resource
    get "/resources/:resource_id/elements/:element_id" do
      options = get_options(params)
      result = NCBO::ResourceIndex.resources(options)
      # TODO: Use the element method instead (Paul is fixing bug)
      #result = NCBO::ResourceIndex.element(params["element_id"], params["resource_id"], options)
      #binding.pry
      reply massage_resources(result)
    end

    #
    # TODO: enable POST methods?
    #

    def massage_elements(element_array)
      elements = []
      element_array.each do |e|
        element = {
            "id" => e[:localElementId],
            "fields" => []
        }
        e[:text].each do |name, description|
          weight = 0.0
          e[:weights].each {|hsh| weight = hsh[:weight] if hsh[:name] == name}
          ontID = [e[:ontoIds][name]].flatten  # Wrap Fixnum or Array into Array
          element["fields"].push(
            {
              "name" => name,
              "text" => description,
              "weight" => weight,
              "associatedOntologies" => ontID
            }
          )
        end
        elements.push element
      end
      return elements
    end

    def massage_resources(resource_array)
      # Remove resource content
      resource_array.each do |r|
        r.delete :workflowCompletedDate
        r.delete :contexts
      end
      return resource_array
    end

  end # namespace "/resource_index"

end # class ResourceIndexController
