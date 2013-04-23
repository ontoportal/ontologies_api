require 'sinatra/base'
require 'redis'

module Sinatra
  module Helpers
    module ResourceIndexHelper
      REDIS = Redis.new(host: LinkedData.settings.redis_host)

      def shorten_uri(uri, ont_format = "")
        uri = uri.to_s
        if ont_format.eql?("OBO")
          if uri.start_with?("http://purl.org/obo/owl/")
            last_fragment = uri.split("/").last.split("#")
            prefix = last_fragment[0]
            mod_code = last_fragment[1]
          elsif uri.start_with?("http://purl.obolibrary.org/obo/")
            last_fragment = uri.split("/").last.split("_")
            prefix = last_fragment[0]
            mod_code = last_fragment[1]
          elsif uri.start_with?("http://www.cellcycleontology.org/ontology/owl/")
            last_fragment = uri.split("/").last.split("#")
            prefix = last_fragment[0]
            mod_code = last_fragment[1]
          elsif uri.start_with?("http://purl.bioontology.org/ontology/")
            last_fragment = uri.split("/")
            prefix = last_fragment[-2]
            mod_code = last_fragment[-1]
          end
          short_id = "#{prefix}:#{mod_code}"
        else
          # Everything other than OBO
          uri_parts = uri.split("/")
          short_id = uri_parts.last
          short_id = short_id.split("#").last if short_id.include?("#")
        end
        short_id
      end

      def uri_from_short_id(short_id, version_id)
        REDIS.get("ri:#{version_id}:#{short_id}")
      end

      def acronym_from_version_id(version_id)
        REDIS.hmget("ri:#{version_id}", "acronym").first
      end

    end
  end
end

helpers Sinatra::Helpers::ResourceIndexHelper
