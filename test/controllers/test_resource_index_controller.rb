require_relative '../test_case'
require 'json-schema'

class TestResourceIndexController < TestCase

  DEBUG_MESSAGES=false

  # JSON Schema
  # json-schema for description and validation of REST json responses.
  # http://tools.ietf.org/id/draft-zyp-json-schema-03.html
  # http://tools.ietf.org/html/draft-zyp-json-schema-03
  RESOURCE_SCHEMA_STR = <<-END_RESOURCE_SCHEMA_STR
  {
    "type": "object",
    "title": "resource",
    "description": "A Resource Index resource.",
    "additionalProperties": false,
    "properties": {
      "resourceName": {
        "type": "string",
        "required": true
      },
      "resourceId": {
        "type": "string",
        "required": true
      },
      "mainContext": {
        "type": "string",
        "required": true
      },
      "resourceURL": {
        "type": "string",
        "format": "uri",
        "required": true
      },
      "resourceElementURL": {
        "type": "string",
        "format": "uri"
      },
      "resourceDescription": {
        "type": "string"
      },
      "resourceLogo": {
        "type": "string",
        "format": "uri"
      },
      "lastUpdateDate": {
        "type": "string",
        "format": "datetime"
      },
      "totalElements": {
        "type": "number"
      }
    }
  }
  END_RESOURCE_SCHEMA_STR
  RESOURCES_SCHEMA_STR = <<-END_RESOURCES_SCHEMA_STR
  {
    "type": "array",
    "title": "resources",
    "description": "An array of Resource Index resource objects.",
    "items": {
      "type": "object"
    }
  }
  END_RESOURCES_SCHEMA_STR

  ELEMENT_FIELD_SCHEMA_STR = <<-END_ELEMENT_FIELD_SCHEMA_STR
  {
    "type": "object",
    "title": "element_field",
    "description": "A Resource Index element field.",
    "additionalProperties": false,
    "properties": {
      "name": {
        "type": "string",
        "required": true
      },
      "text": {
        "type": "string",
        "required": true
      },
      "weight": {
        "type": "number",
        "required": true
      },
      "associatedOntologies": {
        "type": "array",
        "required": true
      }
    }
  }
  END_ELEMENT_FIELD_SCHEMA_STR
  ELEMENT_SCHEMA_STR = <<-END_ELEMENT_SCHEMA_STR
  {
    "type": "object",
    "title": "element",
    "description": "A Resource Index element.",
    "additionalProperties": false,
    "properties": {
      "id": {
        "type": "string",
        "required": true
      },
      "fields": {
        "type": "array",
        "required": true
      }
    }
  }
  END_ELEMENT_SCHEMA_STR
  ELEMENTS_SCHEMA_STR = <<-END_ELEMENTS_SCHEMA_STR
  {
    "type": "array",
    "title": "elements",
    "description": "An array of Resource Index element objects.",
    "items": {
      "type": "object"
    }
  }
  END_ELEMENTS_SCHEMA_STR


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
    #get "/resource_index/search?classes[acronym1][classid1,classid2,classid3]&classes[acronym2][classid1,classid2]"
    acronym = 'nif'
    classid1 = 'obo2:DOID_1909' # Melanoma
    classid2 = 'activity:IRB'
    get "/resource_index/ranked_elements?classes[#{acronym}]=#{classid1}"
    _response_status(200, last_response)
    #validate_json(last_response.body, RESOURCE_SCHEMA_STR, true)
    results = MultiJson.load(last_response.body)
    results["resources"].each do |r|
      elements = r["elements"]
      validate_json(MultiJson.dump(elements), ELEMENT_SCHEMA_STR, true)
      elements.each do |e|
        fields = e["fields"]
        validate_json(MultiJson.dump(fields), ELEMENT_FIELD_SCHEMA_STR, true)
      end
    end
    #binding.pry
    #assert_instance_of(Array, elements)
    # TODO: Check for an empty Array?
  end

  def test_get_search_classes
    #get "/resource_index/search?classes[acronym1][classid1,classid2,classid3]&classes[acronym2][classid1,classid2]"
    #resource_id = 'GEO'
    acronym = 'nif'
    classid1 = 'obo2:DOID_1909' # Melanoma
    classid2 = 'activity:IRB'
    get "/resource_index/search?classes[#{acronym}]=#{classid1}"
    #get "/resource_index/search?classes[#{acronym}]=#{classid1},#{classid2}"
    _response_status(200, last_response)
    validate_json(last_response.body, RESOURCE_SCHEMA_STR, true)
    resources = MultiJson.load(last_response.body)
    assert_instance_of(Array, resources)
    not assert_empty(resources, "Error: empty resources.")
    # TODO: Check for an empty Array?
  end

  def test_get_resources
    get '/resource_index/resources'
    _response_status(200, last_response)
    validate_json(last_response.body, RESOURCE_SCHEMA_STR, true)
    resources = MultiJson.load(last_response.body)
    assert_instance_of(Array, resources)
  end

  def test_get_resource_element
    resource_id = 'GEO'
    element_id = 'E-GEOD-19229'
    get "/resource_index/resources/#{resource_id}/elements/#{element_id}"
    _response_status(200, last_response)
    validate_json(last_response.body, RESOURCE_SCHEMA_STR, true)
    resources = MultiJson.load(last_response.body)
    assert_instance_of(Array, resources)
  end

  def _response_status(status, response)
    if DEBUG_MESSAGES
      assert_equal(status, response.status, response.body)
    else
      assert_equal(status, response.status)
    end
  end

end

