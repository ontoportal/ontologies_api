class SchemesController < ApplicationController
  get '/ontologies/:ontology/schemes' do
    ont, submission = get_ontology_and_submission
    check_last_modified_segment(LinkedData::Models::Class, [ont.acronym])
    reply submission.all_concepts_schemes
  end

end

