
require 'ncbo_resource_index_client'

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
        options[:elementDetails] = true
        result = NCBO::ResourceIndex.find_by_concept(classes, options)
        reply massage_search(result, options)
      end
    end

    def massage_search(old_response, options)
      # TODO: massage the result format

      contextMap = {
        "mgrepContext" => "directAnnotations",
        "mappingContext" => "mappingAnnotations",
        "isaContext" => "hierarchyAnnotations"
      }
      resources = {}
      #binding.pry
      old_response.each do |a|
        elements = []
        a.annotations.each do |annotation|
          # TODO: massage annotation.concept - change ontology version ID to virtual ID and acronym
          # TODO: use annotation.context[:contextType] to group element annotations
          # TODO: massage annotation.context ?
          element = massage_element(annotation.element, options[:elementDetails])
          elements.push(element)
        end
        resources[a.resource] = {
            "totalElements" => elements.length,
            "elements" => elements
        }
      end
      # TODO: Restructure the output
      return resources
    end

    def massage_search_annotation(a)

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

    # Return specific resources
    get "/resources/:resources" do
      options = get_options(params)
      result = NCBO::ResourceIndex.resources(options)
      reply massage_resources(result)
    end

    # Return specific elements from specific resources
    get "/resources/:resources/elements/:elements" do
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

    def massage_elements(element_array, ranked=true)
      elements = []
      element_array.each { |e| elements.push massage_element(e, ranked) }
      return elements
    end

    def massage_element(e, with_fields=true, with_weight=true)
      element = { "id" => e[:localElementId] }
      if with_fields
        fields = {}
        e[:text].each do |name, description|
          ontID = [e[:ontoIds][name]].compact  # Wrap Fixnum or Array into Array
          fields[name] = {
              "text" => description,
              "associatedOntologies" => ontID
          }
          if with_weight
            weight = 0.0
            e[:weights].each {|hsh| weight = hsh[:weight] if hsh[:name] == name}
            fields[name]["weight"] = weight
          end
        end
        element["fields"] = fields
      end
      return element
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
