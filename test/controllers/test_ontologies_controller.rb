require_relative '../test_case'
require 'json'

class TestOntologiesController < TestCase
  def setup
    _set_vars
    _delete
    _create_models
  end

  def teardown
    _set_vars
    _delete
  end

  def _set_vars
    @acronym = "TST"
    @name = "Test Ontology"
  end

  def _create_models
    test_user = User.new(username: "tim")
    test_user.save
  end

  def _delete
    _delete_onts
    test_user = User.find("tim")
    test_user.delete unless test_user.nil?
  end

  def _delete_onts
    ont = Ontology.find(@acronym)
    ont.delete unless ont.nil?
  end

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

  def test_submissions_for_given_ontology
  end

  def test_create_new_ontology_same_acronym
    ont = Ontology.new(acronym: @acronym, name: @name)
    ont.save

    put "/ontologies/#{@acronym}", :name => @name
    assert last_response.status == 400
  end

  def test_create_new_ontology_invalid
    put "/ontologies/#{@acronym}"
    assert last_response.status == 400
    assert JSON.parse(last_response.body)["errors"]
  end

  def test_create_new_ontology_missing_file_and_pull_location
    put "/ontologies/#{@acronym}", name: @name
    assert last_response.status == 400
    assert JSON.parse(last_response.body)["errors"]
  end

  def test_create_new_ontology_file
    test_file = File.expand_path("../../data/ontology_files/BRO_v3.1.owl", __FILE__)
    put "/ontologies/#{@acronym}", name: @name, ontologyFormat: "OWL", administeredBy: "tim", "file" => Rack::Test::UploadedFile.new(test_file, "")
    assert last_response.status == 201
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

  def test_ontology_properties
  end
end