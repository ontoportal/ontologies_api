require_relative '../test_case'
require 'json-schema'


=begin
class Project < LinkedData::Models::Base
  model :project
  attribute :creator, :cardinality => { :max => 1, :min => 1 }
  attribute :created, :date_time_xsd => true, :cardinality => { :max => 1, :min => 1 }
  attribute :name, :cardinality => { :max => 1, :min => 1 }
  attribute :homePage, :cardinality => { :max => 1, :min => 1 }
  attribute :description, :cardinality => { :max => 1, :min => 1 }
  attribute :contacts, :cardinality => { :max => 1 }
  attribute :ontologyUsed, :instance_of => { :with => :ontology }, :cardinality => { :min => 1 }
end
=end

class TestProjectsController < TestCase

  # JSON Schema
  # This could be in the Project model, see
  # https://github.com/ncbo/ontologies_linked_data/issues/22
  # json-schema for description and validation of REST json responses.
  # http://tools.ietf.org/id/draft-zyp-json-schema-03.html
  # http://tools.ietf.org/html/draft-zyp-json-schema-03
  JSON_SCHEMA_STR = <<-END_JSON_SCHEMA_STR
  {
    "type":"object",
    "title":"Project",
    "description":"A BioPortal project, which may refer to multiple ontologies.",
    "additionalProperties":false,
    "properties":{
      "creator":{ "type":"string", "required": true },
      "created":{ "type":"string", "format":"datetime", "required": true },
      "name":{ "type":"string", "required": true },
      "homePage":{ "type":"string", "format":"uri", "required": true },
      "description":{ "type":"string", "required": true },
      "contacts":{ "type":"string" },
      "ontologyUsed":{ "type":"array", "items":{ "type":"string" } }
    }
  }
  END_JSON_SCHEMA_STR

  def _project_json_schema
    JSON.parse(JSON_SCHEMA_STR)
  end

  def _validate_json(data, list=false)
    # Validate json data against a schema. Note that schema may be more
    # restrictive than serializer.
    schema = _project_json_schema
    assert(
        JSON::Validator.validate(schema, data, :list => list),
        JSON::Validator.fully_validate(schema, data, :validate_schema => true, :list => list).to_s
    )
  end

  def _valid_response_project(response, status)
    assert_equal(status, response.status)
    p = JSON.parse(response.body)
    assert_instance_of(Hash, p)
    assert_equal(@p.name, p['name'])
    _validate_json(p)
    return true
  end

  def _delete(modelList)
    modelList.each do |x|
      next if x.nil?
      x.load
      x.delete
    end
  end

  def teardown
    _delete(LinkedData::Models::User.all)
    _delete(LinkedData::Models::Ontology.all)
    _delete(LinkedData::Models::Project.all)
  end

  def setup
    super
    teardown
    @user = LinkedData::Models::User.new(username: "test_user")
    @user.save
    @ont = LinkedData::Models::Ontology.new(acronym: "TST", name: "TEST ONTOLOGY", administeredBy: @user)
    @ont.save
    @p = LinkedData::Models::Project.new
    @p.creator = @user
    @p.created = DateTime.new
    @p.name = "TestProject" # must be a valid URI
    @p.homePage = "http://www.example.org"
    @p.description = "A test project"
    @p.ontologyUsed = [@ont,]
    @p.save
  end

  def test_all_projects
    get '/projects'
    assert_equal(200, last_response.status)
    projects = JSON.parse(last_response.body)
    assert_instance_of(Array, projects)
    assert_equal(1, projects.length)
    p = projects[0]
    assert_equal(@p.name, p['name'])
    _validate_json(p)
  end

  def test_single_project
    get "/projects/#{@p.name}"
    _valid_response_project(last_response, 200)
  end

  def test_create_new_project
    # Ensure it doesn't exist first (undo the setup creation)
    delete "/projects/#{@p.name}"
    assert_equal(204, last_response.status)
    #params = [
    #  #"name='#{@p.name}'",
    #  "description='#{@p.description}'",
    #  "homePage='#{@p.homePage}'",
    #  "creator='#{@user.username}'",
    #  #"ontologyUsed='#{@p.ontologyUsed.acronym}'"
    #]
    #put "/projects/#{@p.name}?#{params.join('&')}"
    put "/projects/#{@p.name}"
    _valid_response_project(last_response, 201)
    get "/projects/#{@p.name}"
    _valid_response_project(last_response, 200)
  end

  def test_update_replace_project
  end

  def test_update_patch_project
    patch "/projects/#{@p.name}"
    _valid_response_project(last_response, 201)
    get "/projects/#{@p.name}"
    _valid_response_project(last_response, 200)
  end

  #test_update_patch_user
  # add_first_name = {firstName: "Fred"}
  # patch "/users/fred", add_first_name.to_json, "CONTENT_TYPE" => "application/json"
  # assert last_response.status == 204
  # get "/users/fred"
  # fred = JSON.parse(last_response.body)
  # assert fred["firstName"].eql?("Fred")

  def test_delete_project
    delete "/projects/#{@p.name}"
    assert_equal(204, last_response.status)
    get "/projects/#{@p.name}"
    assert_equal(404, last_response.status)
  end

end
