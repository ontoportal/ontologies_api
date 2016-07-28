class SubmissionMetadataController < ApplicationController

  namespace "/submission_metadata" do

    ##
    # Display all metadata for submissions
    get do
      all_attr = []

      LinkedData::Models::OntologySubmission.attributes(:all).each do |attr|

        if LinkedData.settings.id_url_prefix.nil? || LinkedData.settings.id_url_prefix.empty?
          id_url_prefix = "http://data.bioontology.org/"
        else
          id_url_prefix = LinkedData.settings.id_url_prefix
        end

        attr_settings = {}
        attr_settings[:@id] = "#{id_url_prefix}/submission_metadata/#{attr.to_s}"
        attr_settings[:@type] = "#{id_url_prefix}/metadata/SubmissionMetadata"
        attr_settings[:attribute] = attr.to_s

        # Get metadata namespace
        if LinkedData::Models::OntologySubmission.attribute_settings(attr)[:namespace].nil?
          attr_settings[:namespace] = nil
        else
          attr_settings[:namespace] = LinkedData::Models::OntologySubmission.attribute_settings(attr)[:namespace].to_s
        end

        # Get metadata label if one
        if LinkedData::Models::OntologySubmission.attribute_settings(attr)[:label].nil?
          attr_settings[:label] = nil
        else
          attr_settings[:label] = LinkedData::Models::OntologySubmission.attribute_settings(attr)[:label]
        end

        # Get if it is an extracted metadata
        if LinkedData::Models::OntologySubmission.attribute_settings(attr)[:extractedMetadata]
          attr_settings[:extracted] = true
        else
          attr_settings[:extracted] = false
        end

        # Get mappings of the metadata
        if LinkedData::Models::OntologySubmission.attribute_settings(attr)[:metadataMappings].nil?
          attr_settings[:metadataMappings] = nil
        else
          attr_settings[:metadataMappings] = LinkedData::Models::OntologySubmission.attribute_settings(attr)[:metadataMappings]
        end

        # Get enforced from the metadata
        if LinkedData::Models::OntologySubmission.attribute_settings(attr)[:enforce].nil?
          attr_settings[:enforce] = []
        else
          attr_settings[:enforce] = []
          LinkedData::Models::OntologySubmission.attribute_settings(attr)[:enforce].each do |enforced|
            attr_settings[:enforce] << enforced.to_s
          end
        end

        attr_settings[:@context] =  {
            "@vocab" => "#{id_url_prefix}metadata/"
        }

        all_attr << attr_settings
      end

      reply all_attr
    end

  end

end