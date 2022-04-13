class SchemesController < ApplicationController
  get '/ontologies/:ontology/schemes' do
    ont, submission = get_ontology_and_submission
    attributes, page, size, filter_by_label, order_by, bring_unmapped_needed  =  settings_params

    page_data = LinkedData::Models::SKOS::Scheme.where
                                            .in(submission)
                                            .include(attributes)

    page_data = page_data.all
    if bring_unmapped_needed
      LinkedData::Models::SKOS::Scheme.in(submission).models(page_data).include(:unmapped).all
    end

    reply page_data
  end

end

