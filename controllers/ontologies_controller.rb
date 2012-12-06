class OntologiesController < ApplicationController
  namespace "/ontologies" do
    # Display all ontologies
    get do
    end

    # Display the most recent submission of the ontology
    get '/:ontology' do
      submission = params[:ontology_submission_id]
    end

    # Display all submissions of an ontology
    get '/:ontology/submissions' do
      submission = params[:ontology_submission_id]
    end

    # Create a new ontology
    post do
    end

    # Create a new submission of an existing ontology
    put '/:ontology' do
    end

    # Update via delete/create for an existing submission of an ontology
    put '/:ontology/:ontology_submission_id' do
    end

    # Update an existing submission of an ontology
    patch '/:ontology/:ontology_submission_id' do
    end

    # Delete an ontology and all its versions
    delete '/:ontology' do
    end

    # Delete a specific ontology submission
    delete '/:ontology/:ontology_submission_id' do
    end

    # Download an ontology
    get '/:ontology/download' do
      submission = params[:ontology_submission_id]
    end

    # Properties for given ontology
    get '/:ontology/properties' do
    end

  end
end