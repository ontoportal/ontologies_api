require_relative '../test_case_helpers'

class TestResourceIndexHelper < TestCaseHelpers
  def test_shorten_uri
    # OBO URIs
    term_id = "term_id"
    short = helper.shorten_uri("http://purl.org/obo/owl/#{term_id}")
    assert short == term_id

    short = helper.shorten_uri("http://purl.obolibrary.org/obo/#{term_id}")
    assert short == term_id

    short = helper.shorten_uri("http://www.cellcycleontology.org/ontology/owl/#{term_id}")
    assert short == term_id
    short = helper.shorten_uri("http://purl.bioontology.org/ontology/#{term_id}")
    assert short == term_id

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
    uri = helper.uri_from_short_id("TM817086", "45215")
    assert uri == "http://who.int/ictm/constitution#TM817086"
  end

  def test_ontology_uri_from_acronym
    uri = helper.ontology_uri_from_acronym("BRO")
    assert uri == "http://data.bioontology.org/ontologies/BRO"
  end

  def test_virtual_id_from_uri
    virtual_id = helper.virtual_id_from_uri("http://data.bioontology.org/ontologies/BRO")
    assert virtual_id == 1104
  end
end