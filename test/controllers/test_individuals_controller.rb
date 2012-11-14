require_relative '../test_case'

class TestIndividualsController < TestCase

  def test_individuals_for_ontology
    ontology = "ncit"
    get "/ontologies/#{ontology}/individuals"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_individuals_for_class
    ontology = "ncit"
    cls = "test_class"
    get "/ontologies/#{ontology}/classes/#{cls}/individuals"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_individual
    ontology = "ncit"
    individual = "test_individual"
    get "/ontologies/#{ontology}/individuals/#{individual}"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

end