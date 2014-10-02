require 'sinatra/base'

module Sinatra
  module Helpers
    module UsersHelper
      def filter_for_user_onts(obj)
        return obj unless obj.is_a?(Enumerable)
        return obj unless env["REMOTE_USER"]
        return obj if env["REMOTE_USER"].customOntology.empty?
        return obj if params["ignore_custom_ontologies"]

        user = env["REMOTE_USER"]

        if obj.first.is_a?(LinkedData::Models::Ontology)
          obj.delete_if {|o| !user.custom_ontology_id_set.include?(o.id.to_s)}
        end

        obj
      end
    end
  end
end

helpers Sinatra::Helpers::UsersHelper