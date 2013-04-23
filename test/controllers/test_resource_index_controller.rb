require_relative '../test_case'
require 'json-schema'

class TestResourceIndexController < TestCase

  DEBUG_MESSAGES=false

  # JSON Schema
  # json-schema for description and validation of REST json responses.
  # http://tools.ietf.org/id/draft-zyp-json-schema-03.html
  # http://tools.ietf.org/html/draft-zyp-json-schema-03



  SEARCH_SCHEMA = <<-END_SEARCH_SCHEMA
  {
    "type": "object",
    "title": "annotations",
    "description": "A hash of Resource Index resource annotations."
  }
  END_SEARCH_SCHEMA

  RESOURCE_SCHEMA = <<-END_RESOURCE_SCHEMA
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
  END_RESOURCE_SCHEMA
  RESOURCES_SCHEMA = <<-END_RESOURCES_SCHEMA
  {
    "type": "array",
    "title": "resources",
    "description": "An array of Resource Index resource objects.",
    "items": {
      "type": "object"
    }
  }
  END_RESOURCES_SCHEMA

  ELEMENT_FIELD_SCHEMA = <<-END_ELEMENT_FIELD_SCHEMA
  {
    "type": "object",
    "title": "element_field",
    "description": "A Resource Index element field.",
    "additionalProperties": false,
    "properties": {
      "text": {
        "type": "string",
        "required": true
      },
      "associatedOntologies": {
        "type": "array",
        "required": true
      },
      "weight": {
        "type": "number"
      }
    }
  }
  END_ELEMENT_FIELD_SCHEMA
  ELEMENT_SCHEMA = <<-END_ELEMENT_SCHEMA
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
        "type": "object",
        "required": true
      }
    }
  }
  END_ELEMENT_SCHEMA
  ELEMENTS_SCHEMA = <<-END_ELEMENTS_SCHEMA
  {
    "type": "array",
    "title": "elements",
    "description": "An array of Resource Index element objects.",
    "items": {
      "type": "object"
    }
  }
  END_ELEMENTS_SCHEMA


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
    #validate_json(last_response.body, RESOURCE_SCHEMA, true)
    results = MultiJson.load(last_response.body)
    results["resources"].each do |r|
      elements = r["elements"]
      validate_json(MultiJson.dump(elements), ELEMENT_SCHEMA, true)
      elements.each do |e|
        # TODO: iterate over the field objects to validate, revise the
        # TODO: wiki page elements section and the massage_elements code.
        e["fields"].each_value do |field|
          validate_json(MultiJson.dump(field), ELEMENT_FIELD_SCHEMA)
        end
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
    validate_json(last_response.body, SEARCH_SCHEMA)
    annotations = MultiJson.load(last_response.body)
    assert_instance_of(Hash, annotations)
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

end

