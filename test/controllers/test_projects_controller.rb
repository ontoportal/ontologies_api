require_relative '../test_case'
require 'json-schema'

class TestProjectsController < TestCase

  DEBUG_MESSAGES=false

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

  # Validate JSON object against a JSON schema.
  # @note schema may be more restrictive than serializer generating json data.
  # @param [Hash] jsonObj ruby hash created by JSON.parse
  # @param [boolean] list set it true for jsonObj array of items to validate
  def _validate_json(jsonObj, list=false)
    jsonSchema = _project_json_schema
    assert(
        JSON::Validator.validate(jsonSchema, jsonObj, :list => list),
        JSON::Validator.fully_validate(jsonSchema, jsonObj, :validate_schema => true, :list => list).to_s
    )
  end

  # Clear the triple store models
  # @param [Array] gooModelArray an array of GOO models
  def _delete_models(gooModelArray)
    gooModelArray.each do |m|
      next if m.nil?
      m.load
      m.delete
    end
  end

  # Clear the triple store models
  def teardown
    _delete_models(LinkedData::Models::Project.all)
    _delete_models(LinkedData::Models::Ontology.all)
    _delete_models(LinkedData::Models::User.all)
    @projectParams = nil
    @user = nil
    @ont = nil
    @p = nil
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
    @p.created = DateTime.new
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
        created: @p.created,
        ontologyUsed: @p.ontologyUsed.first.acronym
    }
  end

  def test_all_projects
    get '/projects'
    _response_status(200, last_response)
    projects = JSON.parse(last_response.body)
    assert_instance_of(Array, projects)
    assert_equal(1, projects.length)
    p = projects[0]
    assert_equal(@p.name, p['name'])
    _validate_json(p)
  end

  def test_project_create_success
    # Ensure it doesn't exist first (undo the setup @p.save creation)
    _project_delete(@p.name)
    put "/projects/#{@p.name}", @projectParams.to_json, "CONTENT_TYPE" => "application/json"
    _response_status(201, last_response)
    _project_get_success(@p.name, true)
  end

  def test_project_create_conflict
    # Fail PUT for any project that already exists.
    put "/projects/#{@p.name}", @projectParams.to_json, "CONTENT_TYPE" => "application/json"
    _response_status(409, last_response)
    # The existing project should remain valid
    _project_get_success(@p.name, true)
  end

  def test_project_create_failure
    # Ensure the project doesn't exist.
    _project_delete(@p.name)
    # Fail PUT for any project with required missing data.
    @projectParams["name"] = nil
    put "/projects/#{@p.name}", @projectParams.to_json, "CONTENT_TYPE" => "application/json"
    _response_status(400, last_response)
    _project_get_failure(@p.name)
  end

  def test_project_update_success
    patch "/projects/#{@p.name}", @projectParams.to_json, "CONTENT_TYPE" => "application/json"
    _response_status(204, last_response)
    _project_get_success(@p.name)
    # TODO: validate the data updated
    #_project_get_success(@p.name, true)
  end

  def test_project_delete
    _project_delete(@p.name)
    _project_get_failure(@p.name)
  end


  def _response_status(status, response)
    if DEBUG_MESSAGES
      assert_equal(status, response.status, response.body)
    else
      assert_equal(status, response.status)
    end
  end

  # Issues DELETE for a project name, tests for a 204 response.
  # @param [String] name project name
  def _project_delete(name)
    delete "/projects/#{name}"
    _response_status(204, last_response)
  end

  # Issues GET for a project name, tests for a 200 response, with optional response validation.
  # @param [String] name project name
  # @param [boolean] validate_data verify response body json content
  def _project_get_success(name, validate_data=false)
    get "/projects/#{name}"
    _response_status(200, last_response)
    if validate_data
      # Assume we have JSON data in the response body.
      p = JSON.parse(last_response.body)
      assert_instance_of(Hash, p)
      assert_equal(@p.name, p['name'], p.to_s)
      _validate_json(p)
    end
  end

  # Issues GET for a project name, tests for a 404 response.
  # @param [String] name project name
  def _project_get_failure(name)
    get "/projects/#{name}"
    _response_status(404, last_response)
  end

end
