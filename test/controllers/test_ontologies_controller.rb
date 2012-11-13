require_relative '../test_case'

class TestOntologiesController < TestCase
  def test_all_ontologies
    get '/ontologies'
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_single_ontology
    ontology = 'ncit'
    get "/ontologies/#{ontology}"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_create_new_ontology
  end

  def test_create_new_ontology_submission
  end

  def test_update_replace_ontology
  end

  def test_update_patch_ontology
  end

  def test_delete_ontology
  end

  def test_delete_ontology_submission
  end

  def test_download_ontology
  end
end