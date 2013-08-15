require_relative '../test_case'

class TestMetricsController < TestCase

  def self.before_suite 
    @@data = {"classes"=>486,
"avg_children"=>5,
"max_children"=>65,
"classes_one_child"=>14,
"classes_25_children"=>2,
"classes_with_no_definition"=>11,
"individuals"=>80,
"properties"=>63,
"max_depth"=>8 }
    options = {ont_count: 2, 
               submission_count: 3, 
               submissions_to_process: [1, 2], 
               process_submission: true, 
               random_submission_count: false}
   LinkedData::SampleData::Ontology.create_ontologies_and_submissions(options)
  end

  def test_all_metrics
    get '/metrics'
    assert last_response.ok?
    metrics = MultiJson.load(last_response.body)
    assert metrics.length == 2
    #TODO: improve this test and test for two different ontologies
    #though this is tested in LD
    metrics.each do |m|
      @@data.each do |k,v|
        assert m[k] == v
      end
      assert m["@id"] == m["submission"].first["@id"] + "/metrics"
    end
  end

  def test_single_metrics
    ontology = 'TEST-ONT-0'
    get "/ontologies/#{ontology}/metrics"
    assert last_response.ok?
    metrics = MultiJson.load(last_response.body)
    @@data.each do |k,v|
      assert metrics[k] == v
    end
  end

  def test_metrics_with_submission_id
    ontology = 'TEST-ONT-0'
    get "/ontologies/#{ontology}/submissions/1/metrics"
    assert last_response.ok?
    metrics = MultiJson.load(last_response.body)
    @@data.each do |k,v|
      assert metrics[k] == v
    end
  end

  def test_metrics_with_submission_id_as_param
    ontology = 'TEST-ONT-0'
    get "/ontologies/#{ontology}/metrics?submissionId=1"
    assert last_response.ok?
    metrics = MultiJson.load(last_response.body)
    @@data.each do |k,v|
      assert metrics[k] == v
    end
  end

end
