require_relative '../test_case'
require 'json-schema'

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
    _delete(LinkedData::Models::Project.all)
    _delete(LinkedData::Models::Ontology.all)
    _delete(LinkedData::Models::User.all)
  end

  def setup
    super
    teardown
    @user = LinkedData::Models::User.new(username: "test_user", email: "test_user@example.org")
    @user.save
    @ont = LinkedData::Models::Ontology.new(acronym: "TST", name: "TEST ONTOLOGY", administeredBy: @user)
    @ont.save
    @p = LinkedData::Models::Project.new
    @p.creator = @user
    #@p.created = DateTime.new
    @p.name = "TestProject" # must be a valid URI
    @p.homePage = "http://www.example.org"
    @p.description = "A test project"
    @p.ontologyUsed = [@ont,]
    @p.save
    @projectParams = {
        name: @p.name,
        description: @p.description,
        homePage: @p.homePage,
        creator: @p.creator.username,
        #created: @p.created,
        ontologyUsed: @p.ontologyUsed.first.acronym
    }
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

  def test_valid_project
    get "/projects/#{@p.name}"
    _valid_response_project(last_response, 200)
  end

  def test_invalid_project
    get "/projects/missing_project"
    assert_equal(404, last_response.status)
  end

  def test_new_project_success
    # Ensure it doesn't exist first (undo the setup creation)
    delete "/projects/#{@p.name}"
    assert_equal(204, last_response.status)
    put "/projects/#{@p.name}", @projectParams.to_json, "CONTENT_TYPE" => "application/json"
    _valid_response_project(last_response, 201)
    test_valid_project
  end

  def test_new_project_failures
    # Fail PUT for any project that already exists.
    put "/projects/#{@p.name}", @projectParams.to_json, "CONTENT_TYPE" => "application/json"
    assert_equal(409, last_response.status)
    # Ensure the project doesn't exist.
    delete "/projects/#{@p.name}"
    assert_equal(204, last_response.status)
    # Fail PUT for any project with required missing data.
    @projectParams["name"] = nil
    put "/projects/#{@p.name}", @projectParams.to_json, "CONTENT_TYPE" => "application/json"
    assert_equal(400, last_response.status)
  end

  def test_update_project_success
    patch "/projects/#{@p.name}", @projectParams.to_json, "CONTENT_TYPE" => "application/json"
    assert_equal(204, last_response.status)
    test_valid_project
  end

  def test_delete_project
    delete "/projects/#{@p.name}"
    assert_equal(204, last_response.status)
    get "/projects/#{@p.name}"
    assert_equal(404, last_response.status)
  end

end
