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
          pc = ProvisionalClass.find(id).first
        end

        relations_param.each do |rel|
          rel_obj = instance_from_params(ProvisionalRelation, rel)
          rel_obj.source = pc

          if rel_obj.valid?
            ret_val["objects"] << rel_obj
          else
            ret_val["errors"][rel_obj.id] = rel_obj.errors
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