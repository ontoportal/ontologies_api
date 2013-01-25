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

  def setup
    super
    teardown
    @user = LinkedData::Models::User.new(username: "DLW")
    @user.save
    @ont = LinkedData::Models::Ontology.new(acronym: "TST", name: "TEST", administeredBy: @user)
    @ont.save
    @p = LinkedData::Models::Project.new
    @p.creator = @user
    @p.created = DateTime.new
    @p.name = "TestProject" # must be a valid URI
    @p.homePage = "http://www.example.org"
    @p.description = "A test project"
    @p.ontologyUsed = [@ont,]
    @p.save

    # Schema objects (add these to the Project model as a class variable?)
    type_string = { "type" => "string" }
    @ontology_json_schema = type_string
    @ontologies_json_schema = {
        "type" => "array",
        "items" => @ontology_json_schema
    }
    @project_json_schema = {
        "type" => "object",
        "properties" => {
            "description" => type_string,
            "created" => type_string,
            "homePage" => type_string,
            "name" => type_string,
            "creator" => type_string,
            "ontologyUsed" => @ontologies_json_schema
        }
    }
    @projects_json_schema = {
        "type" => "object",
        "properties" => {
            "type" => "array",
            "items" => @project_json_schema
        }
    }


  end

  def teardown
    delete(LinkedData::Models::User.all)
    delete(LinkedData::Models::Ontology.all)
    delete(LinkedData::Models::Project.all)
  end

  def delete(modelList)
    modelList.each do |x|
      next if x.nil?
      x.load
      x.delete
    end
  end

  def test_all_projects
    get '/projects'
    assert_equal last_response.status, 200
    body = JSON.parse(last_response.body)
    assert_instance_of(Array, body)
    # Validate the json against a schema, body contains a list of projects
    assert(
        JSON::Validator.validate(@project_json_schema, body, :validate_schema => true, :list => true),
        JSON::Validator.fully_validate(@project_json_schema, body, :validate_schema => true, :list => true).to_s
    )
    #assert_equal(body.length, 1)
    #p = body[0]
    #assert_equal(p['name'], @p.name)
  end

  def test_single_project
    get "/projects/#{@p.name}"
    assert_equal last_response.status, 200
    p = JSON.parse(last_response.body)
    assert_instance_of(Hash, p)
    assert_equal(@p.name, p['name'])
    # Validate the json against a schema, body contains a list of projects
    assert(
        JSON::Validator.validate(@project_json_schema, p, :validate_schema => true),
        JSON::Validator.fully_validate(@project_json_schema, p, :validate_schema => true).to_s
    )
  end

  def test_create_new_project
  end

  def test_update_replace_project
  end

  def test_update_patch_project
  end

  def test_delete_project
  end

end
