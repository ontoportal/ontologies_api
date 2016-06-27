class SubmissionMetadataController < ApplicationController

  namespace "/submission_metadata" do

    ##
    # Display all metadata for submissions
    get do
      all_attr = []

      LinkedData::Models::OntologySubmission.attributes(:all).each do |attr|

        attr_settings = {}
        attr_settings[:attribute] = attr.to_s

        # Get metadata namespace
        if LinkedData::Models::OntologySubmission.attribute_settings(attr)[:namespace].nil?
          attr_settings[:namespace] = nil
        else
          attr_settings[:namespace] = LinkedData::Models::OntologySubmission.attribute_settings(attr)[:namespace].to_s
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

        all_attr << attr_settings
      end

      reply all_attr
    end

  end

end