class IndividualsController < ApplicationController
  # Display invididuals for an ontology
  get '/ontologies/:ontology/individuals' do
    submission = params[:ontology_submission_id]
  end

  # Display invididuals for an ontology
  get '/ontologies/:ontology/individuals/:individual' do
    submission = params[:ontology_submission_id]
  end

  # Display individuals for a class
  get '/ontologies/:ontology/classes/:cls/individuals' do
    submission = params[:ontology_submission_id]
  end
end