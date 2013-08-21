require_relative '../test_case'

class TestOntologySubmissionsController < TestCase
  def self.before_suite
    _set_vars
    _delete
    _create_user
    _create_onts
  end

  def self.after_suite
    _set_vars
    _delete
    self.new("after_suite").delete_ontologies_and_submissions
  end

  def self._set_vars
    @@acronym = "TST"
    @@name = "Test Ontology"
    @@test_file = File.expand_path("../../data/ontology_files/BRO_v3.1.owl", __FILE__)
    @@file_params = {
      name: @@name,
      hasOntologyLanguage: "OWL",
      administeredBy: "tim",
      "file" => Rack::Test::UploadedFile.new(@@test_file, ""),
      released: DateTime.now.to_s,
      contact: {name: "test_name", email: "test@example.org"}
    }
  end

  def self._create_user
    username = "tim"
    test_user = User.new(username: username, email: "#{username}@example.org", password: "password")
    test_user.save if test_user.valid?
    @@user = test_user.valid? ? test_user : User.find(username).first
  end

  def self._delete
    _delete_onts
    test_user = User.find("tim").first
    test_user.delete unless test_user.nil?
  end

  def self._create_onts
    ont = Ontology.new(acronym: @@acronym, name: @@name, administeredBy: [@@user])
    ont.save
  end

  def self._delete_onts
    ont = Ontology.find(@@acronym).first
    subs = OntologySubmission.where(ontology: ont).all
    subs.each do |s|
      s.delete
    end
    ont.delete unless ont.nil?
  end

  def test_submissions_for_given_ontology
    num_onts_created, created_ont_acronyms = create_ontologies_and_submissions(ont_count: 1)
    ontology = created_ont_acronyms.first
    get "/ontologies/#{ontology}/submissions"
    assert last_response.ok?

    submissions_goo = OntologySubmission.where(ontology: { acronym: ontology}).to_a

    submissions = MultiJson.load(last_response.body)
    assert submissions.length == submissions_goo.length
  end

  def test_create_new_submission_missing_file_and_pull_location
    post "/ontologies/#{@@acronym}/submissions", name: @@name, hasOntologyLanguage: "OWL"
    assert last_response.status == 422
    assert MultiJson.load(last_response.body)["errors"]
  end

  def test_create_new_submission_file
    post "/ontologies/#{@@acronym}/submissions", @@file_params
    assert last_response.status == 201

    get "/ontologies/#{@@acronym}"
    ont = MultiJson.load(last_response.body)
    assert ont["acronym"].eql?(@@acronym)
  end

  def test_create_new_submission_and_parse
    post "/ontologies/#{@@acronym}/submissions", @@file_params
    assert last_response.status == 201
    sub = MultiJson.load(last_response.body)

    get "/ontologies/#{@@acronym}/submissions/#{sub['submissionId']}?include=all"
    ont = MultiJson.load(last_response.body)
    assert ont["ontology"]["acronym"].eql?(@@acronym)
    post "/ontologies/#{@@acronym}/submissions/#{sub['submissionId']}/parse"
    assert last_response.status == 200

    max = 25
    while (ont["submissionStatus"] == "UPLOADED" and max > 0)
      get "/ontologies/#{@@acronym}/submissions/#{sub['submissionId']}?include=all"
      assert last_response.status == 200
      ont = MultiJson.load(last_response.body)
      max = max - 1
      sleep(1.5)
    end
    assert max > 0
    #EVENTUALLY HAS TO ASSERT AGAINST READY
    assert ont["submissionStatus"] == "RDF"

    #we should be able to get roots
    get "/ontologies/#{@@acronym}/classes/roots"
    assert last_response.status == 200
    roots = MultiJson.load(last_response.body)
    assert roots.length > 0
  end

  def test_create_new_ontology_submission
    post "/ontologies/#{@@acronym}/submissions", @@file_params
    assert last_response.status == 201
  end

  def test_patch_ontology_submission
    num_onts_created, created_ont_acronyms = create_ontologies_and_submissions(ont_count: 1)
    ont = Ontology.find(created_ont_acronyms.first).include(submissions: [:submissionId, ontology: :acronym]).first
    assert(ont.submissions.length > 0)
    submission = ont.submissions[0]

    new_values = {description: "Testing new description changes"}
    patch "/ontologies/#{submission.ontology.acronym}/submissions/#{submission.submissionId}", MultiJson.dump(new_values), "CONTENT_TYPE" => "application/json"
    assert last_response.status == 204

    get "/ontologies/#{submission.ontology.acronym}/submissions/#{submission.submissionId}"
    submission = MultiJson.load(last_response.body)
    assert submission["description"].eql?("Testing new description changes")
  end

  def test_delete_ontology_submission
    num_onts_created, created_ont_acronyms = create_ontologies_and_submissions(ont_count: 1, random_submission_count: false, submission_count: 5)
    acronym = created_ont_acronyms.first
    submission_to_delete = (1..5).to_a.shuffle.first
    delete "/ontologies/#{acronym}/submissions/#{submission_to_delete}"
    assert last_response.status == 204

    get "/ontologies/#{acronym}/submissions/#{submission_to_delete}"
    assert last_response.status == 404
  end

  def test_download_submission
    # not implemented yet
  end

  def test_ontology_submission_properties
    # not implemented yet
  end
end
