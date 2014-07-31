require_relative '../test_case'

class TestOntologiesController < TestCase
  def self.before_suite
    _set_vars
    _delete
    _create_user
    _create_onts
  end

  def teardown
    self.class._delete_onts
    self.class._create_onts
  end

  def self._set_vars
    @@acronym = "TST"
    @@name = "Test Ontology"
    @@file_params = {
      name: @@name,
      hasOntologyLanguage: "OWL",
      administeredBy: ["tim"]
    }

    @@view_acronym = 'TST_VIEW'
    @@view_name = 'Test View of Test Ontology'
    @@view_file_params = {
        name: @@view_name,
        hasOntologyLanguage: "OWL",
        administeredBy: ["tom"]
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
    ont.save if ont.valid?

    view = Ontology.new(acronym: @@view_acronym, name: @@view_name, administeredBy: [@@user], viewOf: ont)
    view.save
  end

  def self._delete_onts
    ont = Ontology.find(@@acronym).first
    ont.delete unless ont.nil?
    view = Ontology.find(@@view_acronym).first
    view.delete unless view.nil?
  end

  def test_all_ontologies
    num_onts_created, created_ont_acronyms = create_ontologies_and_submissions()

    get '/ontologies'
    assert last_response.ok?

    onts = MultiJson.load(last_response.body)
    assert onts.length >= num_onts_created

    all_ont_acronyms = []
    onts.each do |ont|
      all_ont_acronyms << ont["acronym"]
    end

    created_ont_acronyms.each do |acronym|
      assert all_ont_acronyms.include?(acronym)
    end
  end

  def test_single_ontology
    num_onts_created, created_ont_acronyms = create_ontologies_and_submissions(ont_count: 1)
    ontology = created_ont_acronyms.first
    get "/ontologies/#{ontology}"
    assert last_response.ok?

    ont = MultiJson.load(last_response.body)
    assert ont["acronym"] = ontology
  end

  def test_create_ontology
    self.class._delete_onts
    put "/ontologies/#{@@acronym}", @@file_params
    assert last_response.status == 201

    delete "/ontologies/#{@@acronym}"
    post "/ontologies/", @@file_params.merge(acronym: @@acronym)
    assert last_response.status == 201
  end

  def test_create_new_ontology_same_acronym
    put "/ontologies/#{@@acronym}", :name => @@name
    assert last_response.status == 409
  end

  def test_create_new_ontology_same_name
    put "/ontologies/XXX", :name => @@name
    assert last_response.status == 409
  end

  def test_create_new_ontology_acronym_invalid
    # acronym rules:
    #   - 0-9, a-z, A-Z, dash, and underscore (no spaces)
    #   - acronym must start with a letter (upper or lower case)
    #   - acronym length <= 16 characters
    #   - acronym and name must be unique
    #
    # Must begin with A-Z
    ont_name = 'Invalid Ontology Acronym'
    put "/ontologies/*abc123", :name => ont_name
    check400 last_response
    put "/ontologies/_abc123", :name => ont_name
    check400 last_response
    put "/ontologies/-abc123", :name => ont_name
    check400 last_response
    put "/ontologies/123abc", :name => ont_name
    check400 last_response
    # Must be all upper case.
    put "/ontologies/abc", :name => ont_name
    check400 last_response
    # test acronym is too long (17 > 16), otherwise this one is OK
    put "/ontologies/A1234567890123456", :name => ont_name
    check400 last_response
    # test acronym with any invalid character
    put "/ontologies/A*", :name => ont_name
    check400 last_response
  end

  def test_create_new_ontology_invalid
    put "/ontologies/NO_PROPERTIES"
    assert last_response.status == 422
    assert MultiJson.load(last_response.body)["errors"]
  end

  def test_patch_ontology
    name = "Test new name"
    new_name = {name: name}
    patch "/ontologies/#{@@acronym}", MultiJson.dump(new_name), "CONTENT_TYPE" => "application/json"
    assert last_response.status == 204

    get "/ontologies/#{@@acronym}"
    ont = MultiJson.load(last_response.body)
    assert ont["name"].eql?(name)
  end

  def test_delete_ontology
    delete "/ontologies/#{@@acronym}"
    assert last_response.status == 204

    get "/ontologies/#{@@acronym}"
    assert last_response.status == 404
  end

  def test_download_ontology
    num_onts_created, created_ont_acronyms, onts = create_ontologies_and_submissions(ont_count: 1, submission_count: 1, process_submission: true)
    assert_equal(1, num_onts_created, msg="Failed to create 1 ontology?")
    assert_equal(1, onts.length, msg="Failed to create 1 ontology?")
    ont = onts.first
    assert_instance_of(Ontology, ont, msg="ont is not a #{Ontology.class}")
    # Clear restrictions on downloads
    LinkedData::OntologiesAPI.settings.restrict_download = []
    # Download the latest submission (the generic ontology download)
    acronym = created_ont_acronyms.first
    get "/ontologies/#{acronym}/download"
    assert_equal(200, last_response.status, msg='failed download for ontology : ' + get_errors(last_response))
    # Add restriction on download
    LinkedData::OntologiesAPI.settings.restrict_download = [acronym]
    # Try download
    get "/ontologies/#{acronym}/download"
    # download should fail with a 403 status
    assert_equal(403, last_response.status, msg='failed to restrict download for ontology : ' + get_errors(last_response))
    # Clear restrictions on downloads
    LinkedData::OntologiesAPI.settings.restrict_download = []
    # see also test_ontologies_submissions_controller::test_download_submission
  end

  def test_download_ontology_csv
    num_onts_created, created_ont_acronyms, onts = create_ontologies_and_submissions(ont_count: 1, submission_count: 1, process_submission: true)
    ont = onts.first
    acronym = created_ont_acronyms.first

    get "/ontologies/#{acronym}/download?download_format=csv"
    assert_equal(200, last_response.status, msg="Download failure for '#{acronym}' ontology: " + get_errors(last_response))

    # Download should fail with a 400 status.
    get "/ontologies/#{acronym}/download?download_format=csr"
    assert_equal(400, last_response.status, msg="Download failure for '#{acronym}' ontology: " + get_errors(last_response))
  end

  #def test_download_restricted_ontology
  #  num_onts_created, created_ont_acronyms, onts = create_ontologies_and_submissions(ont_count: 1, submission_count: 1, process_submission: true)
  #  assert_equal(1, num_onts_created, msg="Failed to create 1 ontology?")
  #  assert_equal(1, onts.length, msg="Failed to create 1 ontology?")
  #  ont = onts.first
  #  assert_instance_of(Ontology, ont, msg="ont is not a #{Ontology.class}")
  #  # Add restriction on download
  #  acronym = created_ont_acronyms.first
  #  LinkedData::OntologiesAPI.settings.restrict_download = [acronym]
  #  # Try download
  #  get "/ontologies/#{acronym}/download"
  #  # download should fail with a 403 status
  #  assert_equal(403, last_response.status, msg='failed to restrict download for ontology : ' + get_errors(last_response))
  #  # Clear restrictions on downloads
  #  LinkedData::OntologiesAPI.settings.restrict_download = []
  #  # see also test_ontologies_submissions_controller::test_download_submission
  #end

  def test_ontology_properties
    # not implemented yet
  end


  private

  def check400(response)
    assert response.status >= 400
    assert MultiJson.load(response.body)["errors"]
  end



end
