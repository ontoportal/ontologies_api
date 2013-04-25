require_relative '../test_case'
require 'json-schema'

class TestResourceIndexController < TestCase

  DEBUG_MESSAGES=false

  # JSON Schema
  # json-schema for description and validation of REST json responses.
  # http://tools.ietf.org/id/draft-zyp-json-schema-03.html
  # http://tools.ietf.org/html/draft-zyp-json-schema-03

  SEARCH_SCHEMA = <<-END_SCHEMA
  {
    "type": "object",
    "title": "annotations",
    "description": "A hash of Resource Index resource annotations."
  }
  END_SCHEMA

  SEARCH_ANNOTATIONS_SCHEMA = <<-END_SCHEMA
  {
    "type": "array",
    "title": "resources",
    "description": "An array of Resource Index resource objects.",
    "items": { "type": "object" }
  }
  END_SCHEMA

  SEARCH_ANNOTATION_SCHEMA = <<-END_SCHEMA
  {
      "type": "object",
      "title": "annotation",
      "description": "A Resource Index annotation.",
      "additionalProperties": false,
      "properties": {
          "annotatedClass": { "type": "object", "required": true },
          "annotationType": { "type": "string", "required": true },
          "elementField": { "type": "string", "required": true },
          "elementId": { "type": "string", "required": true },
          "from": { "type": "number", "required": true },
          "to": { "type": "number", "required": true }
      }
  }
  END_SCHEMA

  RESOURCES_SCHEMA = <<-END_SCHEMA
  {
    "type": "array",
    "title": "resources",
    "description": "An array of Resource Index resource objects.",
    "items": { "type": "object" }
  }
  END_SCHEMA

  RESOURCE_SCHEMA = <<-END_SCHEMA
  {
    "type": "object",
    "title": "resource",
    "description": "A Resource Index resource.",
    "additionalProperties": false,
    "properties": {
      "resourceName": { "type": "string", "required": true },
      "resourceId": { "type": "string", "required": true },
      "mainContext": { "type": "string", "required": true },
      "resourceURL": { "type": "string", "format": "uri", "required": true },
      "resourceElementURL": { "type": "string", "format": "uri" },
      "resourceDescription": { "type": "string" },
      "resourceLogo": { "type": "string", "format": "uri" },
      "lastUpdateDate": { "type": "string", "format": "datetime" },
      "totalElements": { "type": "number" }
    }
  }
  END_SCHEMA

  ELEMENTS_SCHEMA = <<-END_SCHEMA
  {
    "type": "object",
    "title": "elements",
    "description": "A hash of Resource Index element objects."
  }
  END_SCHEMA

  ELEMENT_SCHEMA = <<-END_SCHEMA
  {
    "type": "object",
    "title": "element",
    "description": "A Resource Index element."
  }
  END_SCHEMA

  ELEMENT_FIELD_SCHEMA = <<-END_SCHEMA
  {
    "type": "object",
    "title": "element_field",
    "description": "A Resource Index element field.",
    "additionalProperties": false,
    "properties": {
      "text": { "type": "string", "required": true },
      "associatedOntologies": { "type": "array", "items": { "type": "string" }, "required": true },
      "weight": { "type": "number", "required": true }
    }
  }
  END_SCHEMA

  def teardown
    delete_goo_models(LinkedData::Models::Ontology.all)
    delete_goo_models(LinkedData::Models::User.all)
    @params = nil
    @user = nil
    @ont = nil
    @p = nil
  end

  def setup
    @user = LinkedData::Models::User.new(username: "test_user", email: "test_user@example.org", password: "password")
    @user.save
    @ont = LinkedData::Models::Ontology.new(acronym: "TST", name: "TEST ONTOLOGY", administeredBy: @user)
    @ont.save
    #@params = {
    #    acronym: @p.acronym.value,
    #    name: @p.name.value,
    #    description: @p.description.value,
    #    homePage: @p.homePage.value,
    #    creator: @p.creator.username.value,
    #    created: @p.created.value,
    #    institution: @p.institution.value,
    #    ontologyUsed: @p.ontologyUsed.first.acronym.value
    #}
  end

  def test_get_ranked_elements
    #get "/resource_index/ranked_elements?classes[acronym1][classid1,classid2,classid3]&classes[acronym2][classid1,classid2]"
    endpoint='ranked_elements'
    acronym = 'DOID'        # Human disease ontology
    classid1 = 'DOID:1324' # lung cancer
    # TODO: test additional class in REST call
    #classid2 = 'DOID:11920' # tracheal cancer
    get "/resource_index/#{endpoint}?classes[#{acronym}]=#{classid1}"
    #get "/resource_index/#{endpoint}?classes[#{acronym}]=#{classid1},#{classid2}"
    _response_status(200, last_response)
    # TODO: validate the ranked elements response data
    #validate_json(last_response.body, RESOURCE_SCHEMA, true)
    results = MultiJson.load(last_response.body)
    #validate_json(MultiJson.dump(results["resources"]), RESOURCE_SCHEMA, true)
    #results["resources"].each { |r| validate_elements(r["elements"]) }
    refute_empty(results["resources"], "ERROR: empty results['resources']")
  end

  def test_get_search_classes
    #get "/resource_index/search?classes[acronym1][classid1,classid2,classid3]&classes[acronym2][classid1,classid2]"
    #resource_id = 'GEO'
    endpoint='search'
    acronym = 'DOID'        # Human disease ontology
    classid1 = 'DOID:1324'  # lung cancer
    # TODO: test additional class in REST call
    #classid2 = 'DOID:11920' # tracheal cancer
    get "/resource_index/#{endpoint}?classes[#{acronym}]=#{classid1}"
    #get "/resource_index/#{endpoint}?classes[#{acronym}]=#{classid1},#{classid2}"
    _response_status(200, last_response)
    validate_json(last_response.body, SEARCH_SCHEMA)
    annotations = MultiJson.load(last_response.body)
    assert_instance_of(Hash, annotations)
    annotations.each_value do |v|
      validate_json(MultiJson.dump(v["annotations"]), SEARCH_ANNOTATION_SCHEMA, true)
      validate_elements(v["annotatedElements"])
    end
  end

  def test_get_resources
    get '/resource_index/resources'
    _response_status(200, last_response)
    validate_json(last_response.body, RESOURCE_SCHEMA, true)
    resources = MultiJson.load(last_response.body)
    assert_instance_of(Array, resources)
    # TODO: Add element validations, as in test_get_ranked_elements
  end

  def test_get_resource_element
    resource_id = 'GEO'
    element_id = 'E-GEOD-19229'
    get "/resource_index/resources/#{resource_id}/elements/#{element_id}"
    _response_status(200, last_response)
    validate_json(last_response.body, RESOURCE_SCHEMA, true)
    resources = MultiJson.load(last_response.body)
    assert_instance_of(Array, resources)
    # TODO: Add element validations, as in test_get_ranked_elements
  end

  def _response_status(status, response)
    if DEBUG_MESSAGES
      assert_equal(status, response.status, response.body)
    else
      assert_equal(status, response.status)
    end
  end

  def validate_elements(elements)
    validate_json(MultiJson.dump(elements), ELEMENTS_SCHEMA)
    elements.each_value do |e|
      validate_json(MultiJson.dump(e), ELEMENT_SCHEMA)
      e.each_value do |field|
        validate_json(MultiJson.dump(field), ELEMENT_FIELD_SCHEMA)
      end
    end
  end


end

