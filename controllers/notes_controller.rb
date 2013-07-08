class NotesController < ApplicationController
  ##
  # Ontology notes
  get "/ontologies/:ontology/notes?:include_threads?" do
    ont = Ontology.find(params["ontology"]).include(notes: LinkedData::Models::Note.goo_attrs_to_load(includes_param)).first
    error 404, "You must provide a valid id to retrieve notes for an ontology" if ont.nil?
    notes = ont.notes
    recurse_replies(notes) if params["include_threads"]
    reply notes
  end

  ##
  # Class notes
  get "/ontologies/:ontology/classes/:cls/notes?:include_threads?" do
    ont = Ontology.find(params["ontology"]).include(:submissions).first
    error 404, "You must provide a valid id to retrieve notes for an ontology" if ont.nil?
    cls = LinkedData::Models::Class.find(params["cls"]).in(ont.latest_submission).include(notes: LinkedData::Models::Note.goo_attrs_to_load(includes_param)).first
    error 404, "You must provide a valid class id" if cls.nil?
    notes = cls.notes
    recurse_replies(notes) if params["include_threads"]
    reply notes
  end

  namespace "/notes" do
    # Display all notes
    get "?:include_threads?" do
      notes = LinkedData::Models::Note.where.include(LinkedData::Models::Note.goo_attrs_to_load(includes_param)).to_a
      recurse_replies(notes) if params["include_threads"]
      reply notes
    end

    # Display a single note
    get '/:noteid?:include_threads?' do
      noteid = params["noteid"]
      note = LinkedData::Models::Note.find(noteid).include(LinkedData::Models::Note.goo_attrs_to_load(includes_param)).first
      error 404, "Note #{noteid} not found" if note.nil?
      recurse_replies(note) if params["include_threads"]
      reply 200, note
    end

    # Create a note with the given parameters
    post do
      note = note_from_params

      if note.valid?
        note.save
      else
        error 422, note.errors
      end
      reply 201, note
    end

    # Update an existing submission of an note
    patch '/:noteid' do
      noteid = params["noteid"]
      note = LinkedData::Models::Note.find(noteid).include(LinkedData::Models::Note.attributes + [proposal: LinkedData::Models::Notes::Proposal.attributes]).first

      if note.nil?
        error 404, "Note does not exist, please create using HTTP PUT before modifying"
      else
        note_params = params.dup
        proposal_params = note_params.delete("proposal")

        populate_from_params(note, note_params)

        if proposal_params
          proposal = populate_from_params(note.proposal, proposal_params)
          proposal.save
          note.proposal = proposal
        end

        if note.valid?
          note.save
        else
          error 422, note.errors
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

    def note_from_params
      note_params = params.dup
      proposal_params = clean_notes_hash(note_params.delete("proposal"))
      note = instance_from_params(LinkedData::Models::Note, clean_notes_hash(note_params))

      if proposal_params
        proposal = instance_from_params(LinkedData::Models::Notes::Proposal, proposal_params)
        proposal.save
        note.proposal = proposal
      end

      note
    end

    def clean_notes_hash(hash)
      return if hash.nil?
      hash.keys.each do |key|
        empty = hash[key].respond_to?(:empty) && hash[key].empty?
        empty_string = hash[key].is_a?(String) && hash[key].eql?("")
        all_empty = hash[key].is_a?(Enumerable) && hash[key].all? {|e| e.respond_to?(:empty) && e.empty?}
        hash.delete(key) if hash[key].nil? || empty || empty_string || all_empty
      end
      hash
    end
  end
end