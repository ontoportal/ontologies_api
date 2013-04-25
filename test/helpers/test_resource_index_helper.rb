require_relative '../test_case_helpers'

class TestResourceIndexHelper < TestCaseHelpers
  def test_shorten_uri
    term_id = "termid"
    obo_term_id = "ont:term"

    # OBO URIs
    short = helper.shorten_uri("http://purl.org/obo/owl/ont#term", "OBO")
    assert short == obo_term_id

    short = helper.shorten_uri("http://purl.obolibrary.org/obo/ont_term", "OBO")
    assert short == obo_term_id

    short = helper.shorten_uri("http://www.cellcycleontology.org/ontology/owl/ont#term", "OBO")
    assert short == obo_term_id

    short = helper.shorten_uri("http://purl.bioontology.org/ontology/ont/term", "OBO")
    assert short == obo_term_id

    # OWL URIs
    short = helper.shorten_uri("http://bioontology.org/ontologies/Activity.owl##{term_id}")
    assert short == term_id

    # Regular URIs
    short = helper.shorten_uri("http://bioontology.org/ontologies/brain/#{term_id}")
    assert short == term_id
  end

  def test_acronym_from_version_id
    acronym = helper.acronym_from_version_id("45215")
    assert acronym == "TM-CONST"
  end

  def test_uri_from_short_id
    uri = helper.uri_from_short_id("45215", "TM817086")
    assert uri == "http://who.int/ictm/constitution#TM817086"
  end

  def test_virtual_id_from_uri
    virtual_id = helper.virtual_id_from_uri("http://data.bioontology.org/ontologies/BRO")
    assert virtual_id == 1104
  end
end