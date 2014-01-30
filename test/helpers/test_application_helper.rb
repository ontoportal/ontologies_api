require_relative '../test_case_helpers'

class TestApplicationHelper < TestCaseHelpers

  def self.before_suite
    count, acronyms, @@ontologies = LinkedData::SampleData::Ontology.create_ontologies_and_submissions
  end

  def test_it_escapes_html
    escaped_html = helper.h("<a>http://testlink.com</a>")
    assert escaped_html.eql?("&lt;a&gt;http:&#x2F;&#x2F;testlink.com&lt;&#x2F;a&gt;")
  end

  def test_ontologies_param
    ids = @@ontologies.map {|o| o.id.to_s}
    acronyms = @@ontologies.map {|o| o.id.to_s.split("/").last}
    params = {"ontologies" => acronyms.join(",")}
    ontologies = ontologies_param(params)
    assert ontologies == ids

    params = {"ontologies" => ids.join(",")}
    ontologies = ontologies_param(params)
    assert ontologies == ids

    id_acronym = ids + acronyms
    params = {"ontologies" => id_acronym.join(",")}
    ontologies = ontologies_param(params)
    assert ontologies == (ids + ids)
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
