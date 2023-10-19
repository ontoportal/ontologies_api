require 'sinatra/base'

module Sinatra
  module Helpers
    module AccessControlHelper

      ##
      # For a given object, check the access control settings. If they are restricted, handle appropriately.
      # For a list, this will filter out results. For single objects, if will throw an error if access is denied.
      def check_access(obj)
        return obj unless LinkedData.settings.enable_security
        if obj.is_a?(Enumerable)
            filter_access(obj)
        else
          if obj.respond_to?(:read_restricted?) && obj.read_restricted?
            readable = obj.readable?(env["REMOTE_USER"])
            error 403, "Access denied for this resource" unless readable
          end
        end
        obj
      end

      ##
      # For a given object, check if the current user has permission to perform writes.
      def check_write_access(obj)
        return obj unless LinkedData.settings.enable_security
        if obj.is_a?(LinkedData::Models::Base) && obj.write_restricted?
          writable = obj.writable?(env["REMOTE_USER"])
          error 403, "Access denied for this resource" unless writable
        end
      end

      ##
      # Filter out objects to which the current user does not have access.
      # NOTE: Page collections are not filtered. Data should be filtered before
      #       constructing the page to allow for consistent number of results per page.
      def filter_access(enumerable)
        return enumerable unless LinkedData.settings.enable_security
        return enumerable unless enumerable.first.is_a?(LinkedData::Models::Base)
        enumerable = enumerable.dup if enumerable.frozen?
        LinkedData::Security::AccessControl.filter_unreadable(enumerable, env["REMOTE_USER"])
        enumerable
      end
    end
  end
end

helpers Sinatra::Helpers::AccessControlHelper
