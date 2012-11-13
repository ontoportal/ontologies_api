require_relative '../test_case'

class TestClsesController < TestCase
  def test_all_clses
    ontology = 'ncit'
    get "/ontologies/#{ontology}/classes"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_single_cls
    ontology = 'ncit'
    cls = 'test_cls'
    get "/ontologies/#{ontology}/classes/#{cls}"
    assert last_response.ok?
    assert_equal '', last_response.body
  end
end