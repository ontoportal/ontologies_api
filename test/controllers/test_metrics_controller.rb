require_relative '../test_case'

class TestMetricsController < TestCase
  def test_all_metrics
    get '/metrics'
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_single_metric
    ontology = 'test_ontology'
    get "/ontologies/#{ontology}/metrics"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

end