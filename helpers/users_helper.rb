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

      def send_reset_token(email, username)
        user = LinkedData::Models::User.where(email: email, username: username).include(LinkedData::Models::User.attributes).first
        error 404, "User not found" unless user
        reset_token = token(36)
        user.resetToken = reset_token

        return user if user.valid?

        user.save(override_security: true)
        LinkedData::Utils::Notifications.reset_password(user, reset_token)
        user
      end
      
      def token(len)
        chars = ("a".."z").to_a + ("A".."Z").to_a + ("1".."9").to_a
        token = ""
        1.upto(len) { |i| token << chars[rand(chars.size-1)] }
        token
      end

      def reset_password(email, username, token)
        user = LinkedData::Models::User.where(email: email, username: username).include(User.goo_attrs_to_load(includes_param)).first

        error 404, "User not found" unless user

        user.show_apikey = true

        [user, token.eql?(user.resetToken)]
      end

    end
  end
end

helpers Sinatra::Helpers::UsersHelper