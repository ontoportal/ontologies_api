require 'sinatra/base'

module Sinatra
  module Helpers
    module ResourceIndexHelper

      def classes_error(params)
        msg = "Malformed parameters. Try:\n"
        msg += "classes[ontAcronymA]=classA1,classA2,classA3&classes[ontAcronymB]=classB1,classB2\n"
        msg += "See #{LinkedData.settings.rest_url_prefix}documentation for details.\n\n"
        msg += "Parameters:  #{params.to_s}"
        error 400, msg
      end

      def get_classes(params)
        # Assume request signature of the form:
        # classes[acronym1|URI1]=classid1,classid2,classid3&classes[acronym2|URI2]=classid1,classid2
        classes = []
        if params.key?("classes")
          classes_error(params) if not params["classes"].kind_of? Hash
          class_hash = params["classes"]
          class_hash.each do |k,v|
            # Use 'k' as an ontology acronym or URI, translate it to an ontology virtual ID.
            ont_id = virtual_id_from_acronym(k)
            ont_id = virtual_id_from_uri(k) if ont_id.nil?
            msg = "Ontology #{k} cannot be found in the resource index. "
            msg += "See #{LinkedData.settings.rest_url_prefix}resource_index/ontologies for details."
            error 404, msg if ont_id.nil?
            classes_error(params) if not v.kind_of? String
            # Use 'v' as a CSV list of concepts (class ID)
            v.split(',').each do |class_id|
              # Shorten id, if necessary
              if class_id.start_with?("http://")
                class_id = short_id_from_uri(class_id, ont_id)
              end
              # TODO: Determine whether class_id exists, throw 404 for invalid classes.
              classes.push("#{ont_id}/#{class_id}")
            end
          end
        end
        return classes
      end

      def get_options(params={})
        options = {}

        page, page_size = page_params

        offset, limit = offset_and_limit(page, page_size)
        options[:offset] = offset unless offset.nil?
        options[:limit] = limit unless limit.nil?

        if params["elements"].is_a? String
          params["elements"] = params["elements"].split(',')
        end

        if params["resources"].is_a? String
          params["resources"] = params["resources"].split(',')
        end

        if params['ontologies'].is_a? String
          params['ontologies'] = params['ontologies'].split(',')
        end

        if params['semantic_types'].is_a? String
          params['semantic_types'] = params['semantic_types'].split(',')
        end

        return options
      end
    end
  end
end

helpers Sinatra::Helpers::ResourceIndexHelper
