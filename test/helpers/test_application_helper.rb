require_relative '../test_case_helpers'

class TestApplicationHelper < TestCaseHelpers

  def self.before_suite
    count, acronyms, @@ontologies = LinkedData::SampleData::Ontology.create_ontologies_and_submissions
  end

  def self.after_suite
    @@ontologies.each {|o| o.delete}
  end

  def test_it_escapes_html
    escaped_html = helper.h("<a>http://testlink.com</a>")
    assert escaped_html.eql?("&lt;a&gt;http:&#x2F;&#x2F;testlink.com&lt;&#x2F;a&gt;")
  end

  def test_ontologies_param
    params = {"ontologies" => "TEST-ONT-0,TEST-ONT-0-1"}
    ontologies = helper.ontologies_param(params)
    assert ontologies == ["http://data.bioontology.org/ontologies/TEST-ONT-0", "http://data.bioontology.org/ontologies/TEST-ONT-0-1"]

    params = {"ontologies" => "http://data.bioontology.org/ontologies/TEST-ONT-0,http://data.bioontology.org/ontologies/TEST-ONT-0-1"}
    ontologies = helper.ontologies_param(params)
    assert ontologies == ["http://data.bioontology.org/ontologies/TEST-ONT-0", "http://data.bioontology.org/ontologies/TEST-ONT-0-1"]

    params = {"ontologies" => "http://data.bioontology.org/ontologies/TEST-ONT-0,TEST-ONT-0-1"}
    ontologies = helper.ontologies_param(params)
    assert ontologies == ["http://data.bioontology.org/ontologies/TEST-ONT-0", "http://data.bioontology.org/ontologies/TEST-ONT-0-1"]
  end

  def test_ontology_uri_from_acronym
    @@ontologies.each do |ont|
      ont.bring(:acronym)
      uri = helper.ontology_uri_from_acronym(ont.acronym)
      assert uri == ont.id
    end
  end

  def test_acronym_from_ontology_uri
    @@ontologies.each do |ont|
      ont.bring(:acronym)
      acronym = helper.acronym_from_ontology_uri(ont.id)
      assert acronym == ont.acronym
    end
  end

end