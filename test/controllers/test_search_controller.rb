require_relative '../test_case'

class TestSearchController < TestCase

  def self.before_suite
    LinkedData::SampleData::Ontology.delete_ontologies_and_submissions
    @@ontologies = LinkedData::SampleData::Ontology.sample_owl_ontologies
  end

  def self.after_suite
    LinkedData::SampleData::Ontology.delete_ontologies_and_submissions
  end

  def test_search
    get '/search?q=ontology'
    assert last_response.ok?

    acronyms = @@ontologies.map {|ont|
      ont.bring_remaining
      ont.acronym
    }
    results = MultiJson.load(last_response.body)

    results["collection"].each do |doc|
      acronym = doc["links"]["ontology"].split('/')[-1]
      assert acronyms.include? (acronym)
    end
  end

  def test_search_ontology_filter
    acronym = "MCCLTEST-0"
    get "/search?q=cell%20li*&ontologies=#{acronym}"
    assert last_response.ok?
    results = MultiJson.load(last_response.body)

    doc = results["collection"][0]
    assert_equal "cell line", doc["prefLabel"]
    assert_equal "http://localhost:9393/ontologies/MCCLTEST-0", doc["links"]["ontology"]

    results["collection"].each do |doc|
      acr = doc["links"]["ontology"].split('/')[-1]
      assert_equal acr, acronym
    end
  end

  def test_search_other_filters
    acronym = "MCCLTEST-0"
    get "/search?q=receptor%20antagonists&ontologies=#{acronym}&exactMatch=true"
    assert last_response.ok?
    results = MultiJson.load(last_response.body)
    assert_equal results["collection"].length, 1

    get "search?q=data&requireDefinitions=true"
    assert last_response.ok?
    results = MultiJson.load(last_response.body)
    assert results["collection"].length == 46

    get "search?q=data&requireDefinitions=false"
    assert last_response.ok?
    results = MultiJson.load(last_response.body)
    assert results["collection"].length > 46
  end

end