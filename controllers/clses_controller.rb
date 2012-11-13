class ClsesController < ApplicationController
  namespace "/ontologies/:ontology/classes" do
    # Default content type (this will need to support all of our content types eventually)
    before { content_type :json }

    # Display all classes
    get do
    end

    # Display a single class
    get '/:cls' do
      submission = params[:ontology_submission_id]
    end

    # Get root classes
    get '/roots' do
    end

    # Get a tree view
    get '/:cls/tree' do
    end

  end
end