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
    num_onts_created, created_ont_acronyms = create_ontologies_and_submissions(ont_count: 1, submission_count: 1, process_submission: true)
    ont = Ontology.find(created_ont_acronyms.first)
    ont.load unless ont.loaded?
    get "/ontologies/#{ont.acronym}/classes/roots"
    assert last_response.ok?
    roots = JSON.parse(last_response.body)
    assert_equal 12, roots.length
    roots.each do |r|
      assert_instance_of String, r["prefLabel"]
    end
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
