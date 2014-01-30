require_relative '../test_case'

class TestSearchController < TestCase

  def self.before_suite
    @@ontologies = LinkedData::SampleData::Ontology.sample_owl_ontologies
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
    assert doc["links"]["ontology"].include? acronym
    results["collection"].each do |doc|
      acr = doc["links"]["ontology"].split('/')[-1]
      assert_equal acr, acronym
    end
  end

  def test_search_other_filters
    acronym = "MCCLTEST-0"
    get "/search?q=receptor%20antagonists&ontologies=#{acronym}&exact_match=true"
    assert last_response.ok?
    results = MultiJson.load(last_response.body)
    assert_equal results["collection"].length, 1

    get "search?q=data&require_definition=true"
    assert last_response.ok?
    results = MultiJson.load(last_response.body)
    assert results["collection"].length == 46

    get "search?q=data&require_definition=false"
    assert last_response.ok?
    results = MultiJson.load(last_response.body)
    assert results["collection"].length > 46
  end

  def test_wildcard_search
    get "/search?q=lun*"
    assert last_response.ok?
    results = MultiJson.load(last_response.body)
    coll = results["collection"]
  end

end
