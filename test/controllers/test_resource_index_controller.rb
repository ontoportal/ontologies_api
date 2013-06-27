require_relative '../test_case'

class TestResourceIndexController < TestCase

  DEBUG_MESSAGES = true

  # Populate the ontology dB
  def self.before_suite
    test_ontology_acronyms = ["BRO"]
    acronyms = []
    LinkedData::Models::Ontology.all {|o| acronyms << o.acronym}
    @@created_acronyms = []
    begin
      @user = LinkedData::Models::User.new(username: "test_user", email: "test_user@example.org", password: "password")
      @user.save
      test_ontology_acronyms.each do |acronym|
        next if acronyms.include?(acronym)
        ontology_data = {
            acronym: acronym,
            name: "#{acronym} ontology",
            administeredBy: [@user]
        }
        ontology = LinkedData::Models::Ontology.new(ontology_data)
        ontology.save
        @@created_acronyms << acronym
        # Create a dummy ontology submission.
        ont_data = LinkedData::SampleData::Ontology.create_ontologies_and_submissions(ont_count: 1, submission_count: 1)
        ont_new = ont_data[2][0]
        ont_new.bring(:submissions)
        submission = ont_new.submissions.last  # get the last submission, regardless of parsing status
        submission.bring_remaining
        submission.submissionStatus = LinkedData::Models::SubmissionStatus.find(LinkedData::Models::SubmissionStatus.parsed_code).first
        submission.ontology = ontology
        submission.save
      end
    rescue Exception => e
      puts "Failure to create ontology or user in before_suite: delete and recreate triple store.\n"
      raise e
    end
  end

  def self.after_suite
    begin
      LinkedData::SampleData::Ontology.delete_ontologies_and_submissions
      @user = nil
      @@created_acronyms.each do |acronym|
        ontology = LinkedData::Models::Ontology.find(acronym).first
        ontology.delete unless ontology.nil?
      end
    rescue Exception => e
      puts "Failure to delete ontology or user in after_suite\n"
      raise e
    end
  end


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

  ONTOLOGIES_SCHEMA = <<-END_SCHEMA
  {
    "type": "array",
    "title": "ontologies",
    "description": "An array of Resource Index ontologies.",
    "items": { "type": "object" }
  }
  END_SCHEMA

  ONTOLOGY_SCHEMA = <<-END_SCHEMA
  {
    "type": "object",
    "title": "ontology",
    "description": "A Resource Index ontology.",
    "additionalProperties": false,
    "properties": {
      "ontologyName": { "type": "string", "required": true },
      "ontologyURI": { "type": "string", "format": "uri", "required": true }
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

  ELEMENTS_SCHEMA = <<-END_SCHEMA
  {
    "type": "array",
    "title": "elements",
    "description": "An array of Resource Index element objects."
  }
  END_SCHEMA

  ELEMENT_SCHEMA = <<-END_SCHEMA
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
    acronym = 'BRO'
    classid1 = 'BRO:Algorithm'
    classid2 = 'BRO:Graph_Algorithm'
    #
    # Note: Using classid1 encounters network timeout exception
    #
    #rest_target = "/resource_index/ranked_elements?classes[#{acronym}]=#{classid1},#{classid2}"
    rest_target = "/resource_index/ranked_elements?classes[#{acronym}]=#{classid2}"
    puts rest_target if DEBUG_MESSAGES
    get rest_target
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
    # 1104 is BRO
    # 1104, BRO:Algorithm, http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Algorithm
    # 1104, BRO:Graph_Algorithm, http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Graph_Algorithm
    #
    # Note: Using classid1 encounters network timeout exception for that term
    #
    rest_search = "/resource_index/search"
    ont_idS = 'BRO'
    class_idS = 'BRO:Graph_Algorithm'
    ont_idF = CGI::escape('http://data.bioontology.org/ontologies/BRO')
    class_idF = CGI::escape('http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Graph_Algorithm')
    rest_param_list = [
        "?classes[#{ont_idS}]=#{class_idS}",
        "?classes[#{ont_idF}]=#{class_idF}"
    ]
    rest_param_list.each do |param|
      rest_target = rest_search + param
      puts rest_target if DEBUG_MESSAGES
      get rest_target
      _response_status(200, last_response)
      validate_json(last_response.body, PAGE_SCHEMA)
      page = MultiJson.load(last_response.body)
      annotations = page["collection"]
      assert_instance_of(Array, annotations)
      validate_json(MultiJson.dump(annotations), SEARCH_RESOURCE_SCHEMA, true)
      annotations.each do |a|
        validate_json(MultiJson.dump(a["annotations"]), SEARCH_ANNOTATION_SCHEMA, true)
        validate_annotated_elements(a["annotatedElements"])
      end
    end

  end

  def test_get_ontologies
    rest_target = '/resource_index/ontologies'
    puts rest_target if DEBUG_MESSAGES
    get rest_target
    _response_status(200, last_response)
    validate_json(last_response.body, PAGE_SCHEMA)
    ontology_pages = MultiJson.load(last_response.body)
    assert_instance_of(Hash, ontology_pages)
    assert_instance_of(Array, ontology_pages['collection'])
    validate_json(MultiJson.dump(ontology_pages['collection']), ONTOLOGIES_SCHEMA)
    validate_json(MultiJson.dump(ontology_pages['collection']), ONTOLOGY_SCHEMA, true)
  end

  def test_get_resources
    rest_target = '/resource_index/resources'
    puts rest_target if DEBUG_MESSAGES
    get rest_target
    _response_status(200, last_response)
    validate_json(last_response.body, RESOURCE_SCHEMA, true)
    resources = MultiJson.load(last_response.body)
    assert_instance_of(Array, resources)
  end

  def test_get_resource_element
    resource_id = 'AE'
    element_id = 'E-GEOD-19229'
    rest_target = "/resource_index/resources/#{resource_id}/elements/#{element_id}"
    puts rest_target if DEBUG_MESSAGES
    get rest_target
    _response_status(200, last_response)
    element = MultiJson.load(last_response.body)
    validate_element(element)
  end


private


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
    validate_json(MultiJson.dump(elements), ELEMENT_SCHEMA, true)
    elements.each {|e| validate_element(e) }
  end

  def validate_element(element)
    validate_json(MultiJson.dump(element), ELEMENT_SCHEMA)
    element["fields"].each_value do |field|
      validate_json(MultiJson.dump(field), ELEMENT_FIELD_SCHEMA)
    end
  end

end

