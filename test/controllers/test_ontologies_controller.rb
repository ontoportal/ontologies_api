require_relative '../test_case'

class TestOntologiesController < TestCase
  def self.before_suite
    _set_vars
    _delete
    _create_user
    _create_onts
  end

  def self.after_suite
    _set_vars
    _delete
    self.new("after_suite").delete_ontologies_and_submissions()
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

  def test_create_new_ontology_invalid
    put "/ontologies/ont_no_properties"
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
    # not implemented yet
  end

  def test_ontology_properties
    # not implemented yet
  end
end
