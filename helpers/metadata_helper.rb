require 'sinatra/base'
require 'date'

module Sinatra
  module Helpers
    module MetadataHelper

      def klass_metadata(klass, type)
        all_attr = []
        klass.attributes(:all).each do |attr|

          if LinkedData.settings.id_url_prefix.nil? || LinkedData.settings.id_url_prefix.empty?
            id_url_prefix = "http://data.bioontology.org/"
          else
            id_url_prefix = LinkedData.settings.id_url_prefix
          end

          attr_settings = {}
          attr_settings[:@id] = "#{id_url_prefix}#{type}/#{attr.to_s}"
          attr_settings[:@type] = "#{id_url_prefix}metadata/#{type.camelize}"
          attr_settings[:attribute] = attr.to_s

          # Get metadata namespace
          if klass.attribute_settings(attr)[:namespace].nil?
            attr_settings[:namespace] = nil
          else
            attr_settings[:namespace] = klass.attribute_settings(attr)[:namespace].to_s
          end

          # Get metadata label if one
          if klass.attribute_settings(attr)[:label].nil?
            attr_settings[:label] = nil
          else
            attr_settings[:label] = klass.attribute_settings(attr)[:label]
          end

          # Get if it is an extracted metadata
          if klass.attribute_settings(attr)[:extractedMetadata]
            attr_settings[:extracted] = true
          else
            attr_settings[:extracted] = false
          end

          # Get mappings of the metadata
          if klass.attribute_settings(attr)[:metadataMappings].nil?
            attr_settings[:metadataMappings] = nil
          else
            attr_settings[:metadataMappings] = klass.attribute_settings(attr)[:metadataMappings]
          end

          # Get enforced from the metadata
          if klass.attribute_settings(attr)[:enforce].nil?
            attr_settings[:enforce] = []
          else
            attr_settings[:enforce] = []
            klass.attribute_settings(attr)[:enforce].each do |enforced|
              next if enforced.is_a? Proc
              attr_settings[:enforce] << enforced.to_s
            end
          end

          # Get enforcedValues from the metadata
          attr_settings[:enforcedValues] = klass.attribute_settings(attr)[:enforcedValues]

          # Get display from the metadata
          if klass.attribute_settings(attr)[:display].nil?
            attr_settings[:category] = "no"
          else
            attr_settings[:category] = klass.attribute_settings(attr)[:display]
          end

          unless klass.attribute_settings(attr)[:helpText].nil?
            attr_settings[:helpText] = klass.attribute_settings(attr)[:helpText]
          end

          unless klass.attribute_settings(attr)[:description].nil?
            attr_settings[:description] = klass.attribute_settings(attr)[:description]
          end

          unless klass.attribute_settings(attr)[:example].nil?
            attr_settings[:example] = klass.attribute_settings(attr)[:example]
          end

          attr_settings[:@context] =  {
            "@vocab" => "#{id_url_prefix}metadata/"
          }

          all_attr << attr_settings
        end
        all_attr
      end
    end
  end
end

helpers Sinatra::Helpers::MetadataHelper

