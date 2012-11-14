require_relative '../test_case'

class TestNotesController < TestCase
  def test_all_notes
    get '/notes'
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_single_note
    note = 'test_note'
    get "/notes/#{note}"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_create_new_note
  end

  def test_update_replace_note
  end

  def test_update_patch_note
  end

  def test_delete_note
  end

  def test_notes_for_ontology
  end

  def test_notes_for_class
  end
end