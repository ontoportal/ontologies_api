require 'sinatra/base'

module Sinatra
  module Helpers
    module ProvisionalClassesHelper

      def validate_ontology_and_target_class(rel_obj, rel_params)
        # validate target class and ontology
        return ["`targetClassOntology` parameter #{rel_params["targetClassOntology"]} refers to a non-existing ontology id or acronym"] if rel_obj.targetClassOntology.nil?
        ont = Ontology.find(rel_obj.targetClassOntology.id).first
        sub = ont.latest_submission
        return ["No processed submission found for ontology #{rel_obj.targetClassOntology.id}. A provisional relation must refer to a class in an existing processed ontology submission."] if sub.nil?
        cls = rel_obj.target_class
        return ["Class with id #{rel_obj.targetClassId} in ontology #{rel_obj.targetClassOntology.id} was not found"] if cls.nil?
        []
      end

      def save_provisional_class_relations(relations_param, pc=nil)
        ret_val = {"objects" => [], "errors" => []}

        if relations_param.nil?
          relations_param = []
        elsif !relations_param.kind_of?(Array)
          relations_param = [relations_param]
        end

        # when saving individual relations (apart from saving an entire provisional class with relation)
        # validate that the provisional class specified in the "source" parameter is valid
        if !relations_param.empty? && pc.nil?
          id = uri_as_needed(relations_param[0]["source"])
          pc = ProvisionalClass.find(id).first

          if pc.nil?
            ret_val["errors"] << "A provisional class with id #{id} was not found"
            # set relations_param to an empty array to go directly to return
            relations_param = []
          end
        end

        relations_param.each do |rel|
          rel_obj = instance_from_params(ProvisionalRelation, rel)
          # validate ontology and target class
          err = validate_ontology_and_target_class(rel_obj, rel)

          unless err.empty?
            ret_val["errors"].concat err
            next
          end

          rel_obj.source = pc

          if rel_obj.valid?
            ret_val["objects"] << rel_obj
          else
            ret_val["errors"].concat rel_obj.errors
          end
        end

        if ret_val["errors"].empty?
          ret_val["objects"].each { |obj| obj.save }
        else
          ret_val["objects"] = []
        end

        ret_val
      end

    end
  end
end

helpers Sinatra::Helpers::ProvisionalClassesHelper