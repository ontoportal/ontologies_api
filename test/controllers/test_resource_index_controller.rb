require_relative '../test_case'
require 'json-schema'

class TestResourceIndexController < TestCase

  DEBUG_MESSAGES=false

  # JSON Schema
  # This could be in the Project model, see
  # https://github.com/ncbo/ontologies_linked_data/issues/22
  # json-schema for description and validation of REST json responses.
  # http://tools.ietf.org/id/draft-zyp-json-schema-03.html
  # http://tools.ietf.org/html/draft-zyp-json-schema-03
  #JSON_SCHEMA_STR = <<-END_JSON_SCHEMA_STR
  #{
  #  "type":"object",
  #  "title":"Project",
  #  "description":"A BioPortal project, which may refer to multiple ontologies.",
  #  "additionalProperties":true,
  #  "properties":{
  #    "@id":{ "type":"string", "format":"uri", "required": true },
  #    "@type":{ "type":"string", "format":"uri", "required": true },
  #    "acronym":{ "type":"string", "required": true },
  #    "name":{ "type":"string", "required": true },
  #    "creator":{ "type":"string", "required": true },
  #    "created":{ "type":"string", "format":"datetime", "required": true },
  #    "homePage":{ "type":"string", "format":"uri", "required": true },
  #    "description":{ "type":"string", "required": true },
  #    "institution":{ "type":"string" },
  #    "ontologyUsed":{ "type":"array", "items":{ "type":"string" } }
  #  }
  #}
  #END_JSON_SCHEMA_STR


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

  def test_all_resources
    get '/resource_index/resources'
    _response_status(200, last_response)
    #projects = MultiJson.load(last_response.body)
    #assert_instance_of(Array, projects)
    #assert_equal(1, projects.length)
    #p = projects[0]
    #assert_equal(@p.name, p['name'])
    #validate_json(last_response.body, JSON_SCHEMA_STR, true)
  end

  def test_get_classes
    #get "/resource_index/search?classes[acronym1][classid1,classid2,classid3]&classes[acronym2][classid1,classid2]"
    #resource_id = 'GEO'
    acronym = 'NCIt'
    classid1 = 'Melanoma'
    classid2 = 'activity:IRB'
    get "/resource_index/search?classes[#{acronym}]=#{classid1}"
    _response_status(200, last_response)
    #get "/resource_index/search?classes[#{acronym}]=#{classid1},#{classid2}"
    #_response_status(200, last_response)
  end

  def test_get_element_resources
    resource_id = 'GEO'
    element_id = 'E-GEOD-19229'
    get "/resource_index/resources/#{resource_id}/elements/#{element_id}"
    _response_status(200, last_response)
  end

  def _response_status(status, response)
    if DEBUG_MESSAGES
      assert_equal(status, response.status, response.body)
    else
      assert_equal(status, response.status)
    end
  end

end

