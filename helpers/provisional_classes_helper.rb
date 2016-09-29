require 'sinatra/base'

module Sinatra
  module Helpers
    module ProvisionalClassesHelper

      def save_provisional_class_relations(relations_param, pc=nil)
        ret_val = {"objects" => [], "errors" => {}}

        if relations_param.nil?
          relations_param = []
        elsif !relations_param.kind_of?(Array)
          relations_param = [relations_param]
        end

        # when saving individual relations (apart from saving an entire provisional class with relation)
        # retrieve the provisional class designated as the "source"
        if !relations_param.empty? && pc.nil?
          id = uri_as_needed(relations_param[0]["source"])
          pc = LinkedData::Models::ProvisionalClass.find(id).first
        end

        relations_param.each do |rel|
          rel_obj = instance_from_params(LinkedData::Models::ProvisionalRelation, rel)
          rel_obj.source = pc

          if rel_obj.valid?
            ret_val["objects"] << rel_obj
          else
            ret_val["errors"]["#{rel_obj.source.id}_#{rel_obj.targetClassId}"] = rel_obj.errors
          end
        end

        if ret_val["errors"].empty?
          ret_val["objects"].each { |obj| obj.save }
        else
          ret_val["objects"] = []
        end
        ret_val
      end

      def create_provisional_class(params)
        ret_val = {"objects" => [], "errors" => {}}
        relations = params.delete("relations")
        pc = instance_from_params(LinkedData::Models::ProvisionalClass, params)

        if pc.valid?
          pc.save
          rels = save_provisional_class_relations(relations, pc)

          # if there were any errors creating relations, fail the entire transaction
          if rels["errors"].empty?
            ret_val["objects"] << pc
          else
            pc.delete
            ret_val["errors"] = rels["errors"]
          end
        else
          ret_val["errors"] = pc.errors
        end
        ret_val
      end
    end
  end
end

helpers Sinatra::Helpers::ProvisionalClassesHelper