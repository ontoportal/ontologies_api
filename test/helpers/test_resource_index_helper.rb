require_relative '../test_case_helpers'

class TestResourceIndexHelper < TestCaseHelpers

  def self.before_suite
    settings = {ont_count: 1, submission_count: 1, acronym: "BRO", acronym_suffix: ""}
    @@ontology = LinkedData::SampleData::Ontology.create_ontologies_and_submissions(settings)[2].first
  end

  def self.after_suite
    LinkedData::SampleData::Ontology.delete_ontologies_and_submissions
  end

  def test_acronym_from_version_id
    acronym = acronym_from_version_id("45215")
    assert acronym == "TM-CONST"
  end

  def test_uri_from_short_id
    uri = uri_from_short_id("45215", "TM817086")
    assert uri == "http://who.int/ictm/constitution#TM817086"
  end

  def test_virtual_id_from_uri
    virtual_id = virtual_id_from_uri("http://data.bioontology.org/ontologies/BRO")
    assert virtual_id == 1104
  end
end
