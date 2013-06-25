class NotesController < ApplicationController
  ##
  # Ontology notes
  get "/ontologies/:ontology/notes" do
    ont = Ontology.find(params["ontology"]).include(notes: LinkedData::Models::Note.goo_attrs_to_load(includes_param)).first
    error 404, "You must provide a valid id to retrieve notes for an ontology" if ont.nil?
    reply ont.notes
  end

  ##
  # Class notes
  get "/ontologies/:ontology/classes/:cls/notes" do
    ont = Ontology.find(params["ontology"]).include(:submissions).first
    error 404, "You must provide a valid id to retrieve notes for an ontology" if ont.nil?
    cls = LinkedData::Models::Class.find(params["cls"]).in(ont.latest_submission).include(notes: LinkedData::Models::Note.goo_attrs_to_load(includes_param)).first
    error 404, "You must provide a valid class id" if cls.nil?
    reply cls.notes
  end

  namespace "/notes" do
    # Display all notes
    get do
      notes = LinkedData::Models::Note.where.include(LinkedData::Models::Note.goo_attrs_to_load(includes_param)).to_a
      reply notes
    end

    # Display a single note
    get '/:noteid' do
      noteid = params["noteid"]
      note = LinkedData::Models::Note.find(noteid).include(LinkedData::Models::Note.goo_attrs_to_load(includes_param)).first
      error 404, "Note #{noteid} not found" if note.nil?
      reply 200, note
    end

    # Create a note with the given noteid
    post do
      note = instance_from_params(LinkedData::Models::Note, params)

      if note.valid?
        note.save
      else
        error 400, note.errors
      end
      reply 201, note
    end

    # Update an existing submission of an note
    patch '/:noteid' do
      noteid = params["noteid"]
      note = LinkedData::Models::Note.find(noteid).include(LinkedData::Models::Note.attributes).first

      if note.nil?
        error 400, "Note does not exist, please create using HTTP PUT before modifying"
      else
        populate_from_params(note, params)

        if note.valid?
          note.save
        else
          error 400, note.errors
        end
      end
      halt 204
    end

    # Delete a note
    delete '/:noteid' do
      note = LinkedData::Models::Note.find(params["noteid"]).first
      note.delete
      halt 204
    end
  end
end