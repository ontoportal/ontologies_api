
require 'ncbo_resource_index'


class ResourceIndexController < ApplicationController

  # Note get_options method is in resource_index_helper.rb

  namespace "/resource_index" do

    # Return search results
    get '/search' do
      options = get_options(params)
      # Assume request signature of the form:
      # classes[acronym1][classid1,classid2,classid3]&classes[acronym2][classid1,classid2]
      if params.key?("classes")
        classes = []
        class_hash = params["classes"]
        class_hash.each do |k,v|
          # Use 'k' as an ontology acronym, translate it to an ontology virtual ID.
          ont_id = get_ontology_virtual_id(k)
          next if ont_id == nil
          # TODO: use 'v' as a CSV list of concepts (class ID)
          v.split(',').each do |class_id|
            classes.push("#{ont_id}/#{class_id}")
          end
        end
        result = NCBO::ResourceIndex.find_by_concept(classes, options)
        #binding.pry
        reply result
      end
      #
      # TODO: reply with syntax error message?
      #
    end

    # Return all resources
    get "/resources" do
      options = get_options(params)
      response = NCBO::ResourceIndex.resources(options)
      # TODO: massage the return values (may need 'models' for elements, annotations etc.)
      reply response
    end

    # Return a specific resource
    get "/resources/:resource_id" do
      options = get_options(params)
      response = NCBO::ResourceIndex.resources(options)
      # TODO: massage the return values (may need 'models' for elements, annotations etc.)
      reply response
    end

    # Return a specific element from a specific resource
    get "/resources/:resource_id/elements/:element_id" do
      options = get_options(params)
      response = NCBO::ResourceIndex.resources(options)
      # TODO: massage the return values (may need 'models' for elements, annotations etc.)
      reply response
    end

    #
    # TODO: enable POST methods?
    #
  end

end
