require_relative '../test_case'

class TestPropertiesController < TestCase

  def self.before_suite
    count, acronyms, bro = LinkedData::SampleData::Ontology.create_ontologies_and_submissions({
                                                                                                  process_submission: true,
                                                                                                  acronym: "BROSEARCHTEST",
                                                                                                  name: "BRO Search Test",
                                                                                                  file_path: "./test/data/ontology_files/BRO_v3.2.owl",
                                                                                                  ont_count: 1,
                                                                                                  submission_count: 1,
                                                                                                  ontology_type: "VALUE_SET_COLLECTION"
                                                                                              })

    count, acronyms, mccl = LinkedData::SampleData::Ontology.create_ontologies_and_submissions({
                                                                                                   process_submission: true,
                                                                                                   acronym: "MCCLSEARCHTEST",
                                                                                                   name: "MCCL Search Test",
                                                                                                   file_path: "./test/data/ontology_files/CellLine_OWL_BioPortal_v1.0.owl",
                                                                                                   ont_count: 1,
                                                                                                   submission_count: 1
                                                                                               })
    @@ontologies = bro.concat(mccl)
    @@acronyms = @@ontologies.map { |ont| ont.bring_remaining; ont.acronym }
  end

  def self.after_suite
    LinkedData::SampleData::Ontology.delete_ontologies_and_submissions
  end

  def test_properties
    get "/ontologies/#{@@acronyms.first}/properties"
    assert last_response.ok?
    results = MultiJson.load(last_response.body)
    assert_equal 84, results.length

    get "/ontologies/#{@@acronyms.last}/properties"
    assert last_response.ok?
    results = MultiJson.load(last_response.body)
    assert_equal 35, results.length
  end

  def test_single_property
    get "/ontologies/#{@@acronyms.first}/properties/http%3A%2F%2Fbioontology.org%2Fontologies%2FBiomedicalResourceOntology.owl%23Originator"
    assert last_response.ok?
    results = MultiJson.load(last_response.body)
    assert results.is_a?(Hash)
    assert_equal ["Originator"], results["label"]
    assert_equal "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Originator", results["@id"]

    get "/ontologies/#{@@acronyms.first}/properties/http%3A%2F%2Fbioontology.org%2Fontologies%2FBiomedicalResourceOntology.owl%23DummyProp"
    assert_equal 404, last_response.status
  end
end
