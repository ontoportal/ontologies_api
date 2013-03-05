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
    @file_params = {
      name: @name,
      hasOntologyLanguage: "OWL",
      administeredBy: "tim",
      "file" => Rack::Test::UploadedFile.new(@test_file, ""),
      released: DateTime.now.to_s,
      contact: {name: "test_name", email: "test@example.org"}
    }
  end

  def _create_models
    _create_user
  end

  def _create_user
    username = "tim"
    test_user = User.new(username: username, email: "#{username}@example.org", password: "password")
    test_user.save if test_user.valid?
    user = test_user.valid? ? test_user : User.find(username)
    user
  end

  def _delete
    _delete_onts
    test_user = User.find("tim")
    test_user.delete unless test_user.nil?
  end

  def _create_onts
    ont = Ontology.new(acronym: @acronym, name: @name, administeredBy: _create_user)
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

    submissions_goo = OntologySubmission.where(ontology: { acronym: ontology})

    submissions = JSON.parse(last_response.body)
    assert submissions.length == submissions_goo.length

    delete_ontologies_and_submissions()
  end

  def test_create_new_ontology_same_acronym
    _create_onts
    put "/ontologies/#{@acronym}", :name => @name
    assert last_response.status == 409
  end

  def test_create_new_ontology_invalid
    put "/ontologies/#{@acronym}"
    assert last_response.status == 422
    assert JSON.parse(last_response.body)["errors"]
  end

  def test_create_new_ontology_missing_file_and_pull_location
    put "/ontologies/#{@acronym}", name: @name
    assert last_response.status == 422
    assert JSON.parse(last_response.body)["errors"]
  end

  def test_create_new_ontology_file
    put "/ontologies/#{@acronym}", @file_params
    assert last_response.status == 201

    get "/ontologies/#{@acronym}"
    ont = JSON.parse(last_response.body)
    assert ont["acronym"].eql?(@acronym)
  end

  def test_create_new_ontology_and_parse
    put "/ontologies/#{@acronym}", @file_params
    assert last_response.status == 201
    sub = JSON.parse(last_response.body)

    get "/ontologies/#{@acronym}?ontology_submission_id=#{sub['submissionId']}&include=all"
    ont = JSON.parse(last_response.body)
    assert ont["ontology"].eql?("http://data.bioontology.org/metadata/ontology/#{@acronym}")
    post "/ontologies/#{@acronym}/submissions/parse?ontology_submission_id=#{sub['submissionId']}"
    assert last_response.status == 200

    max = 25
    while (ont["submissionStatus"] == "UPLOADED" and max > 0)
      get "/ontologies/#{@acronym}?ontology_submission_id=#{sub['submissionId']}&include=all"
      ont = JSON.parse(last_response.body)
      assert last_response.status == 200
      max = max -1
      sleep(1.5)
    end
    assert max > 0
    #EVENTUALLY HAS TO ASSERT AGAINST READY
    assert ont["submissionStatus"] == "RDF"

    #we should be able to get roots
    get "/ontologies/#{@acronym}/classes/roots"
    assert last_response.status == 200
    roots = JSON.parse(last_response.body)
    assert roots.length > 0
  end

  def test_create_new_ontology_submission
    _create_onts
    post "/ontologies/#{@acronym}/submissions", @file_params
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
    ont = Ontology.find(created_ont_acronyms.first)
    assert(ont.submissions.length > 0)
    submission = ont.submissions[0]
    submission.load unless submission.loaded?
    submission.ontology.load unless submission.ontology.loaded?

    new_values = {description: "Testing new description changes"}
    patch "/ontologies/#{submission.ontology.acronym}/#{submission.submissionId}", new_values.to_json, "CONTENT_TYPE" => "application/json"
    assert last_response.status == 204

    get "/ontologies/#{submission.ontology.acronym}?ontology_submission_id=#{submission.submissionId}"
    submission = JSON.parse(last_response.body)
    assert submission["description"].eql?("Testing new description changes")
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
