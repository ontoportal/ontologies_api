require_relative '../test_case'
require 'json-schema'

class TestResourceIndexController < TestCase

  DEBUG_MESSAGES=false

  # JSON Schema
  # json-schema for description and validation of REST json responses.
  # http://tools.ietf.org/id/draft-zyp-json-schema-03.html
  # http://tools.ietf.org/html/draft-zyp-json-schema-03

  PAGE_SCHEMA = <<-END_SCHEMA
  {
    "type": "object",
    "title": "page",
    "description": "A Resource Index page of results.",
    "additionalProperties": false,
    "properties": {
      "page": { "type": "number", "required": true },
      "pageCount": { "type": "number", "required": true },
      "prevPage": { "type": ["number","null"], "required": true },
      "nextPage": { "type": ["number","null"], "required": true },
      "links": { "type": "object", "required": true },
      "collection": { "type": "array", "required": true }
    }
  }
  END_SCHEMA

  SEARCH_RESOURCES_SCHEMA = <<-END_SCHEMA
  {
    "type": "array",
    "title": "resources",
    "description": "An array of Resource Index resource objects.",
    "items": { "type": "object" }
  }
  END_SCHEMA

  SEARCH_RESOURCE_SCHEMA = <<-END_SCHEMA
  {
    "type": "object",
    "title": "search resource",
    "description": "A Resource Index resource.",
    "additionalProperties": false,
    "properties": {
      "id": { "type": "string", "required": true },
      "annotations": { "type": "array", "required": true },
      "annotatedElements": { "type": "object", "required": true }
    }
  }
  END_SCHEMA

  SEARCH_ANNOTATIONS_SCHEMA = <<-END_SCHEMA
  {
    "type": "array",
    "title": "annotations",
    "description": "An array of Resource Index annotation objects.",
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

  RANKED_ELEMENTS_SCHEMA = <<-END_SCHEMA
  {
    "type": "array",
    "title": "ranked elements",
    "description": "An array of Resource Index ranked element objects.",
    "items": { "type": "object" }
  }
  END_SCHEMA

  RANKED_ELEMENT_SCHEMA = <<-END_SCHEMA
  {
    "type": "object",
    "title": "ranked element",
    "description": "A Resource Index ranked element.",
    "additionalProperties": false,
    "properties": {
      "resourceId": { "type": "string", "required": true },
      "offset": { "type": "number", "required": true },
      "limit": { "type": "number", "required": true },
      "totalResults": { "type": "number", "required": true },
      "elements": { "type": "array", "required": true }
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

  ELEMENTS_ANNOTATED_SCHEMA = <<-END_SCHEMA
  {
    "type": "object",
    "title": "elements",
    "description": "A hash of Resource Index element objects."
  }
  END_SCHEMA

  ELEMENT_ANNOTATED_SCHEMA = <<-END_SCHEMA
  {
    "type": "object",
    "title": "element",
    "description": "A Resource Index element."
  }
  END_SCHEMA

  ELEMENTS_RANKED_SCHEMA = <<-END_SCHEMA
  {
    "type": "array",
    "title": "elements",
    "description": "An array of Resource Index element objects."
  }
  END_SCHEMA

  ELEMENT_RANKED_SCHEMA = <<-END_SCHEMA
  {
    "type": "object",
    "title": "element",
    "description": "A Resource Index element.",
    "additionalProperties": false,
    "properties": {
      "id": { "type": "string", "required": true },
      "fields": { "type": "object", "required": true }
    }
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

  def test_get_ranked_elements
    #get "/resource_index/ranked_elements?{classes}"  # such that {classes} is of the form:
    #classes[acronym1|URI1][classid1,..,classidN]&classes[acronym2|URI2][classid1,..,classidN]
    endpoint='ranked_elements'
    acronym = 'BRO'
    classid1 = 'BRO:Algorithm'
    classid2 = 'BRO:Graph_Algorithm'
    #
    # Note: Using classid1 encounters network timeout exception
    #
    get "/resource_index/#{endpoint}?classes[#{acronym}]=#{classid2}"
    #get "/resource_index/#{endpoint}?classes[#{acronym}]=#{classid1},#{classid2}"
    _response_status(200, last_response)
    validate_json(last_response.body, PAGE_SCHEMA)
    page = MultiJson.load(last_response.body)
    resources = page["collection"]
    refute_empty(resources, "ERROR: empty resources for ranked elements")
    validate_json(MultiJson.dump(resources), RANKED_ELEMENT_SCHEMA, true)
    # TODO: Resolve why ranked elements is different from annotated elements
    resources.each { |r| validate_ranked_elements(r["elements"]) }
  end

  def test_get_search_classes
    #get "/resource_index/search?{classes}"  # such that {classes} is of the form:
    #classes[acronym1|URI1][classid1,..,classidN]&classes[acronym2|URI2][classid1,..,classidN]
    endpoint='search'
    # 1104 is BRO
    # 1104, BRO:Algorithm, http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Algorithm
    # 1104, BRO:Graph_Algorithm, http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Graph_Algorithm
    acronym = 'BRO'
    classid1 = 'BRO:Algorithm'
    classid2 = 'BRO:Graph_Algorithm'
    #
    # Note: Using classid1 encounters network timeout exception for that term
    #
    get "/resource_index/#{endpoint}?classes[#{acronym}]=#{classid2}"
    #get "/resource_index/#{endpoint}?classes[#{acronym}]=#{classid1},#{classid2}"
    _response_status(200, last_response)
    validate_json(last_response.body, PAGE_SCHEMA)
    page = MultiJson.load(last_response.body)
    annotations = page["collection"]
    assert_instance_of(Array, annotations)
    validate_json(MultiJson.dump(annotations), SEARCH_RESOURCE_SCHEMA, true)
    annotations.each do |a|
      validate_json(MultiJson.dump(a["annotations"]), SEARCH_ANNOTATION_SCHEMA, true)
      # TODO: Resolve why ranked elements is different from annotated elements
      validate_annotated_elements(a["annotatedElements"])
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

  def validate_annotated_elements(elements)
    validate_json(MultiJson.dump(elements), ELEMENTS_ANNOTATED_SCHEMA)
    elements.each_value do |e|
      validate_json(MultiJson.dump(e), ELEMENT_ANNOTATED_SCHEMA)
      e.each_value do |field|
        validate_json(MultiJson.dump(field), ELEMENT_FIELD_SCHEMA)
      end
    end
  end

  def validate_ranked_elements(elements)
    validate_json(MultiJson.dump(elements), ELEMENT_RANKED_SCHEMA, true)
    elements.each do |e|
      e["fields"].each_value do |field|
        validate_json(MultiJson.dump(field), ELEMENT_FIELD_SCHEMA)
      end
    end
  end

end

