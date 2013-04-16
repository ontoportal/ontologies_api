
require 'ncbo_resource_index'

class ResourceIndexController < ApplicationController

  # Note: methods from resource_index_helper.rb :
  #  -  get_options(params)
  #  -  get_ontology_virtual_id(ontology_acronym)

  namespace "/resource_index" do

    def set_classes(params)
      # Assume request signature of the form:
      # classes[acronym1][classid1,classid2,classid3]&classes[acronym2][classid1,classid2]
      if params.key?("classes")
        classes = []
        class_hash = params["classes"]
        class_hash.each do |k,v|
          # Use 'k' as an ontology acronym, translate it to an ontology virtual ID.
          ont_id = get_ontology_virtual_id(k)
          next if ont_id == nil
          # Use 'v' as a CSV list of concepts (class ID)
          v.split(',').each do |class_id|
            classes.push("#{ont_id}/#{class_id}")
          end
        end
        return classes
      else
        #
        # TODO: reply with syntax error message?
        #
      end
    end

    # Return search results
    get '/search' do
      options = get_options(params)
      # Assume request signature of the form:
      # classes[acronym1][classid1,classid2,classid3]&classes[acronym2][classid1,classid2]
      classes = set_classes(params)
      if classes.empty?
        #
        # TODO: reply with syntax error message?
        #
      else
        result = NCBO::ResourceIndex.find_by_concept(classes, options)
        reply result
      end
    end

    # Return ranked elements
    get '/ranked_elements' do
      options = get_options(params)
      classes = set_classes(params)
      if classes.empty?
        #
        # TODO: reply with syntax error message?
        #
      else
        result = NCBO::ResourceIndex.ranked_elements(classes, options)
        result.resources.each do |r|
          r[:elements] = elementsMassage(r[:elements])
        end
        reply result
      end
    end

    # Return all resources
    get "/resources" do
      options = get_options(params)
      result = NCBO::ResourceIndex.resources(options)
      reply resourceMassage(result)
    end

    # Return a specific resource
    get "/resources/:resource_id" do
      options = get_options(params)
      result = NCBO::ResourceIndex.resources(options)
      reply resourceMassage(result)
    end

    # Return a specific element from a specific resource
    get "/resources/:resource_id/elements/:element_id" do
      options = get_options(params)
      result = NCBO::ResourceIndex.resources(options)
      # TODO: Use the element method instead (Paul is fixing bug)
      #result = NCBO::ResourceIndex.element(params["element_id"], params["resource_id"], options)
      #binding.pry
      reply resourceMassage(result)
    end

    #
    # TODO: enable POST methods?
    #

    def elementsMassage(elementArray)
      elements = []
      elementArray.each do |e|
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

    def resourceMassage(resourceArray)
      # Remove resource content
      resourceArray.each do |r|
        r.delete :workflowCompletedDate
        r.delete :contexts
      end
      return resourceArray
    end

  end # namespace "/resource_index"

end # class ResourceIndexController
