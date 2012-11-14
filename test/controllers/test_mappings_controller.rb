require_relative '../test_case'

class TestProjectsController < TestCase

  def test_mappings_for_class
    ontology = "ncit"
    cls = "test_class"
    get "/ontologies/#{ontology}/classes/#{cls}/mappings"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_mappings_for_ontology
    ontology = "ncit"
    get "/ontologies/#{ontology}/mappings"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_mappings
    get '/mappings'
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_mapping
    mapping = "test_mapping"
    get "/mappings/#{mapping}"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_create_mapping
  end

  def test_update_replace_mapping
  end

  def test_update_patch_mapping
  end

  def test_delete_mapping
  end

  def test_recent_mappings
    get "/mappings/statistics/recent"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_mappings_statistics_for_ontology
    ontology = "ncit"
    get "/mappings/statistics/ontologies/#{ontology}"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_mappings_popular_classes
    ontology = "ncit"
    get "/mappings/statistics/ontologies/#{ontology}/popular_classes"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_mappings_users
    ontology = "ncit"
    get "/mappings/statistics/ontologies/#{ontology}/users"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

end