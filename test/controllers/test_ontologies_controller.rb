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
    @test_file = File.expand_path("../../data/ontology_files/BRO_v3.1.owl", __FILE__)
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

  def _create_onts
    ont = Ontology.new(acronym: @acronym, name: @name)
    ont.save
  end

  def _delete_onts
    ont = Ontology.find(@acronym)
    ont.delete unless ont.nil?
  end

  def test_all_ontologies
    num_onts_created, created_ont_acronyms = create_ontologies_and_submissions()

    get '/ontologies'
    assert last_response.ok?

    onts = JSON.parse(last_response.body)
    assert onts.length >= num_onts_created

    all_ont_acronyms = []
    onts.each do |ont|
      all_ont_acronyms << ont["acronym"]
    end

    created_ont_acronyms.each do |acronym|
      assert all_ont_acronyms.include?(acronym)
    end

    delete_ontologies_and_submissions()
  end

  def test_single_ontology
    num_onts_created, created_ont_acronyms = create_ontologies_and_submissions(ont_count: 1)
    ontology = created_ont_acronyms.first
    get "/ontologies/#{ontology}"
    assert last_response.ok?

    ont = JSON.parse(last_response.body)
    assert ont["acronym"] = ontology

    delete_ontologies_and_submissions()
  end

  def test_submissions_for_given_ontology
    num_onts_created, created_ont_acronyms = create_ontologies_and_submissions(ont_count: 1)
    ontology = created_ont_acronyms.first
    get "/ontologies/#{ontology}/submissions"
    assert last_response.ok?

    submissions_goo = OntologySubmission.where(acronym: ontology)

    submissions = JSON.parse(last_response.body)
    assert submissions.length == submissions_goo.length

    delete_ontologies_and_submissions()
  end

  def test_create_new_ontology_same_acronym
    _create_onts
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
    put "/ontologies/#{@acronym}", name: @name, ontologyFormat: "OWL", administeredBy: "tim", "file" => Rack::Test::UploadedFile.new(@test_file, "")
    assert last_response.status == 201

    get "/ontologies/#{@acronym}"
    ont = JSON.parse(last_response.body)
    assert ont["acronym"].eql?(@acronym.upcase)
  end

  def test_create_new_ontology_submission
    _create_onts
    post "/ontologies/#{@acronym}/submissions", name: @name, ontologyFormat: "OWL", administeredBy: "tim", "file" => Rack::Test::UploadedFile.new(@test_file, "")
    assert last_response.status == 201
  end

  def test_patch_ontology
    _create_onts
    name = "Test new name"
    new_name = {name: name}
    patch "/ontologies/#{@acronym}", new_name.to_json, "CONTENT_TYPE" => "application/json"
    assert last_response.status == 204

    get "/ontologies/#{@acronym}"
    ont = JSON.parse(last_response.body)
    assert ont["name"].eql?(name)
  end

  def test_patch_ontology_submission
    num_onts_created, created_ont_acronyms = create_ontologies_and_submissions(ont_count: 1)
    submission = Ontology.find(created_ont_acronyms.first).submissions[0]
    submission.load

    new_values = {summaryOnly: false}
    patch "/ontologies/#{submission.acronym}/#{submission.submissionId}", new_values.to_json, "CONTENT_TYPE" => "application/json"
    assert last_response.status == 204

    get "/ontologies/#{submission.acronym}?ontology_submission_id=#{submission.submissionId}"
    submission = JSON.parse(last_response.body)
    assert submission["summaryOnly"] == false
  end

  def test_delete_ontology
    _create_onts
    delete "/ontologies/#{@acronym}"
    assert last_response.status == 204

    get "/ontologies/#{@acronym}"
    assert last_response.status == 404
  end

  def test_delete_ontology_submission
    num_onts_created, created_ont_acronyms = create_ontologies_and_submissions(ont_count: 1, random_submission_count: false, submission_count: 5)
    acronym = created_ont_acronyms.first
    submission_to_delete = (1..5).to_a.shuffle.first
    delete "/ontologies/#{acronym}/#{submission_to_delete}"
    assert last_response.status == 204

    get "/ontologies/#{acronym}?ontology_submission_id=#{submission_to_delete}"
    assert last_response.status == 404
  end

  def test_download_ontology
    # not implemented yet
  end

  def test_ontology_properties
    # not implemented yet
  end
end