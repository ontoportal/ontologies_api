require 'sinatra/base'

module Sinatra
  module Helpers
    module ResourceIndexHelper
      BOOL_MAP = {"and" => :must, "or" => :should}

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
          class_hash.each do |ont_id, cls_ids|
            # Use 'k' as an ontology acronym or URI, translate it to an ontology virtual ID.
            ont = LinkedData::Models::Ontology.find(uri_as_needed(ont_id)).include(:acronym).first
            error 404, "Ontology #{ont_id} cannot be found" if ont.nil?
            sub = ont.latest_submission
            sub.ontology = ont
            classes_error(params) if not cls_ids.kind_of? String

            cls_ids.split(',').each do |cls_id|
              params[:cls] = cls_id # needed for get_class
              cls = get_class(sub)
              classes.push(cls) if cls
              params.delete(:cls) # not used after get_class
            end
          end
        end

        classes
      end

      def format_params(params={})
        page, page_size = page_params
        offset, limit = offset_and_limit(page, page_size)
        params[:from] = offset unless offset.nil?
        params[:size] = limit unless limit.nil?

        if params["match_any_class"]
          if params["match_any_class"].to_s.downcase.eql?("true")
            params[:bool] = :should
          end
        elsif params["boolean_operator"]
          params[:bool] = BOOL_MAP[params.delete("boolean_operator").to_s.downcase]
        end

        params[:expand] = params["expand_class_hierarchy"].to_s.downcase.eql?("true")

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

        nil
      end
    end
  end
end

helpers Sinatra::Helpers::ResourceIndexHelper
