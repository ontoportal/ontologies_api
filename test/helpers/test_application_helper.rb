require_relative '../test_case_helpers'

class TestApplicationHelper < TestCaseHelpers

  def test_it_escapes_html
    escaped_html = helper.h("<a>http://testlink.com</a>")
    assert escaped_html.eql?("&lt;a&gt;http:&#x2F;&#x2F;testlink.com&lt;&#x2F;a&gt;")
  end

  def test_ontologies_param
    params = {"ontologies" => "BRO,NCIt"}
    ontologies = helper.ontologies_param(params)
    assert ontologies == ["http://data.bioontology.org/ontologies/BRO", "http://data.bioontology.org/ontologies/NCIt"]

    params = {"ontologies" => "http://data.bioontology.org/ontologies/BRO,http://data.bioontology.org/ontologies/NCIt"}
    ontologies = helper.ontologies_param(params)
    assert ontologies == ["http://data.bioontology.org/ontologies/BRO", "http://data.bioontology.org/ontologies/NCIt"]

    params = {"ontologies" => "http://data.bioontology.org/ontologies/BRO,NCIt"}
    ontologies = helper.ontologies_param(params)
    assert ontologies == ["http://data.bioontology.org/ontologies/BRO", "http://data.bioontology.org/ontologies/NCIt"]
  end

  def test_ontology_uri_from_acronym
    uri = helper.ontology_uri_from_acronym("BRO")
    assert uri == "http://data.bioontology.org/ontologies/BRO"
  end

end