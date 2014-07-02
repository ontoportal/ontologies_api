require 'multi_json'
require_relative '../test_case'

class TestValidateOntologyFileController < TestCase
  def test_validation_workflow
    skip "Fails on Jenkins test box but not locally, needs to be checked"

    # Bad ontology
    ontfile_path = File.expand_path("../../data/ontology_files/gexo.obo", __FILE__)
    ontfile = Rack::Test::UploadedFile.new(ontfile_path, "text/plain")
    post "/validate_ontology_file", ontology_file: ontfile
    assert_equal 200, last_response.status
    process_id = MultiJson.load(last_response.body)["process_id"]
    response = "processing"
    while response == "processing"
      get "/validate_ontology_file/#{process_id}"
      response = MultiJson.load(last_response.body)
    end
    assert_equal Array, response.class
    assert_equal "LINENO: 37 - expected newline or end of line but found: work, which biologists have found useful to group together for organizational, historic, biophysical or other reasons.\" [BioPAX:Pathway]", response.first

    # Good ontology
    ontfile_path = File.expand_path("../../data/ontology_files/BRO_v3.1.owl", __FILE__)
    ontfile = Rack::Test::UploadedFile.new(ontfile_path, "text/plain")
    post "/validate_ontology_file", ontology_file: ontfile
    assert_equal 200, last_response.status
    process_id = MultiJson.load(last_response.body)["process_id"]
    response = "processing"
    while response == "processing"
      get "/validate_ontology_file/#{process_id}"
      response = MultiJson.load(last_response.body)
    end
    assert_equal Array, response.class
    assert response.empty?
  end
end