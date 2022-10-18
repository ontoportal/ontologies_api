class CollectionsController < ApplicationController

  namespace "/ontologies/:ontology/collections" do
    get  do
      submission, attributes, bring_unmapped_needed = collections_setting_params
      attributes = attributes.delete_if {|x| x.is_a?(Hash)} # remove :member
      page_data = LinkedData::Models::SKOS::Collection.where
                                                  .in(submission)
                                                  .include(attributes)


      page_data = page_data.all
      if bring_unmapped_needed
        LinkedData::Models::SKOS::Collection.in(submission).models(page_data).include(:unmapped).all
      end

      reply page_data
    end
    namespace "/:collection" do
      get  do
        submission, attributes, bring_unmapped_needed = collections_setting_params
        collection_uri = get_collection_uri(params)

        data = LinkedData::Models::SKOS::Collection.find(collection_uri).in(submission).include(attributes).first
        if data && bring_unmapped_needed
          LinkedData::Models::SKOS::Collection.in(submission).models([data]).include(:unmapped).all
        end
        reply data
      end

      get '/members' do
        submission, attributes, bring_unmapped_needed = collections_setting_params
        collection_uri = get_collection_uri(params)
        data = LinkedData::Models::SKOS::Collection.find(collection_uri).in(submission).include(:member).first
        reply data.member
      end
    end
  end


end

