require 'sinatra/base'
require 'redis'

module Sinatra
  module Helpers
    module ResourceIndexHelper
      REDIS = Redis.new(host: LinkedData.settings.redis_host, port: LinkedData.settings.redis_port)

      ##
      # Takes a URI and shortens it (takes off everything except the last fragment) according to NCBO rules.
      # Only OBO format has special processing.
      # The format can be obtained by doing ont.latest_submission.hasOntologyLanguage.acronym.to_s
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

      ##
      # Using the combination of the short_id (EX: "TM122581") and version_id (EX: "42389"),
      # this will do a Redis lookup and give you the full URI. The short_id is based on
      # what is produced by the `shorten_uri` method and should match Resource Index localConceptId output.
      # In fact, doing localConceptId.split("/") should give you the parameters for this method.
      def uri_from_short_id(short_id, version_id)
        REDIS.get("ri:#{version_id}:#{short_id}")
      end

      ##
      # Given a version id, this returns the acronym using a Redis lookup
      def acronym_from_version_id(version_id)
        REDIS.hmget("ri:#{version_id}", "acronym").first
      end

      ##
      # Given an ontology id URI, get the virtual id
      def virtual_id_from_uri(uri)
        virtual_id = REDIS.get("ont_id:virtual:#{uri}")
        virtual_id = virtual_id.to_i unless virtual_id.nil?
        virtual_id
      end

    end
  end
end

helpers Sinatra::Helpers::ResourceIndexHelper
