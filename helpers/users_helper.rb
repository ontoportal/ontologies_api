require 'sinatra/base'

module Sinatra
  module Helpers
    module UsersHelper
      def get_users
        attributes, page, size, _, _ = settings_params(LinkedData::Models::User)
        query = User.where.include(attributes)

        if params['search']
          filter = Goo::Filter.new(:username).regex(params['search'])
          query = query.filter(filter)
        end

        query = query.page(page, size) if page?

        query.all
      end

      def filter_for_user_onts(obj)
        return obj unless obj.is_a?(Enumerable)
        return obj unless env['REMOTE_USER']
        return obj if env['REMOTE_USER'].customOntology.empty?
        return obj if params['ignore_custom_ontologies']

        user = env['REMOTE_USER']

        if obj.first.is_a?(LinkedData::Models::Ontology)
          obj = obj.select { |o| user.custom_ontology_id_set.include?(o.id.to_s) }
        end

        obj
      end
    end
  end
end

helpers Sinatra::Helpers::UsersHelper
