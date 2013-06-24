require 'json'
require_relative '../test_case'

class TestNotesController < TestCase

  def self.before_suite
    @@note_user = "test_note_user"
    _delete_user
    @@user = LinkedData::Models::User.new(
      username: @@note_user,
      email: "note_user@example.org",
      password: "note_user_pass"
    )
    @@user.save

    @@notes = []
    5.times do |i|
      note = LinkedData::Models::Note.new({
        creator: @@user,
        subject: "Test subject #{i}",
        body: "Test body for note #{i}"
      })
      note.save
      @@notes << note
    end
  end

  def self.after_suite
    notes = LinkedData::Models::Note.where(creator: @@user)
    notes.each {|n| n.delete}
    _delete_user
  end

  def self._delete_user
    u = LinkedData::Models::User.find(@@note_user).first
    u.delete unless u.nil?
  end

  def test_all_notes
    get '/notes'
    assert last_response.ok?
    notes = MultiJson.load(last_response.body)
    assert notes.length >= 5
  end

  def test_single_note
    get '/notes'
    notes = MultiJson.load(last_response.body)
    note = notes.first
    get note['@id']
    assert last_response.ok?
    retrieved_note = MultiJson.load(last_response.body)
    assert_equal note["@id"], retrieved_note["@id"]
  end

  def test_note_lifecycle
    note = {
      creator: @@user.id.to_s,
      body: "Testing body",
      subject: "Testing subject"
    }
    post "/notes",MultiJson.dump(note), "CONTENT_TYPE" => "application/json"
    assert last_response.status == 201

    new_note = MultiJson.load(last_response.body)
    get new_note["@id"]
    assert last_response.ok?

    note_changes = {body: "New testing body"}
    patch new_note["@id"], MultiJson.dump(note_changes), "CONTENT_TYPE" => "application/json"
    assert last_response.status == 204
    get new_note["@id"]
    patched_note = MultiJson.load(last_response.body)
    assert_equal patched_note["body"], note_changes[:body]

    delete new_note["@id"]
    assert last_response.status == 204
  end

  def test_notes_for_ontology
  end

  def test_notes_for_class
  end
end