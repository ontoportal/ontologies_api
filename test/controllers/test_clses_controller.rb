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

  def test_roots_for_cls
  end

  def test_tree_for_cls
  end

  def test_ancestors_for_cls
  end

  def test_descendants_for_cls
  end

  def test_children_for_cls
  end

  def test_parents_for_cls
  end

end