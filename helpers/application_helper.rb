require 'sinatra/base'

module Sinatra
  module Helpers
    module ApplicationHelper
      SERIALIZER = LinkedData::Serializer.new

      ##
      # Escape text for use in html
      def h(text)
        Rack::Utils.escape_html(text)
      end

      ##
      # Populate +obj+ using values from +params+
      # Will also try to find related objects using a Goo lookup.
      # TODO: Currerntly, this allows for mass-assignment of everything, which will permit
      # users to overwrite any attribute, including things like passwords.
      # TODO: We should only mass-assign attributes that are declared (if obj.respond_to?...)
      def populate_from_params(obj, params)
        params.each do |attribute, value|
          attr_cls = obj.class.range_class(attribute)
          if attr_cls
            value = attr_cls.find(value)
          end
          obj.send("#{attribute}=", value) # if obj.respond_to?("#{attribute}=")
        end
        obj
      end

      ##
      # Create an instance of +cls+ using provided +params+ to fill in attributes
      def instance_from_params(cls, params)
        n = cls.new
        populate_from_params(n, params)
      end

      ##
      # Serialize objects using a custom serializer that handles content negotiation
      # using the Accept header and "format" query string parameter
      # * +obj+: object to be serialized
      # * +status+: http status code
      def s(obj, status = 200)
        halt 404 if obj.nil? || obj.length == 0

        if obj.respond_to?("each")
          obj.each do |sub_obj|
            sub_obj.load unless !sub_obj.respond_to?("loaded?") || sub_obj.loaded?
          end
        else
          obj.load unless !obj.respond_to?("loaded?") || obj.loaded?
        end
        SERIALIZER.build_response(@env, status: status, ld_object: obj)
      end
    end

    helpers ApplicationHelper
  end
end