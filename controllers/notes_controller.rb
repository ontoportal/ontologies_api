class NotesController < ApplicationController
  namespace "/notes" do
    # Default content type (this will need to support all of our content types eventually)
    before { content_type :json }

    # Display all notes
    get do
    end

    # Display a single note
    get '/:note' do
    end

    # Create a new note
    post do
    end

    # Update via delete/create for an existing submission of an note
    put '/:note' do
    end

    # Update an existing submission of an note
    patch '/:note' do
    end

    # Delete a note
    delete '/:note' do
    end
  end

  # Display notes for an ontology
  get '/ontologies/:ontology/notes' do
  end

  # Display notes for a class
  get '/ontologies/:ontology/classes/:cls/notes' do
  end
end