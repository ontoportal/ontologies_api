require_relative '../test_case'

class TestSearchController < TestCase

  def self.before_suite
     count, acronyms, bro = LinkedData::SampleData::Ontology.create_ontologies_and_submissions({
      process_submission: true,
      acronym: "BROSEARCHTEST",
      name: "BRO Search Test",
      file_path: "./test/data/ontology_files/BRO_v3.2.owl",
      ont_count: 1,
      submission_count: 1,
      ontology_type: "VALUE_SET_COLLECTION"
    })

    count, acronyms, mccl = LinkedData::SampleData::Ontology.create_ontologies_and_submissions({
      process_submission: true,
      acronym: "MCCLSEARCHTEST",
      name: "MCCL Search Test",
      file_path: "./test/data/ontology_files/CellLine_OWL_BioPortal_v1.0.owl",
      ont_count: 1,
      submission_count: 1
    })

    @@ontologies = bro.concat(mccl)

    @@test_user = LinkedData::Models::User.new(
        username: "test_search_user",
        email: "ncbo_search_user@example.org",
        password: "test_user_password"
    )
    @@test_user.save

    # Create a test ROOT provisional class
    @@test_pc_root = LinkedData::Models::ProvisionalClass.new({
      creator: @@test_user,
      label: "Provisional Class - ROOT",
      synonym: ["Test synonym for Prov Class ROOT", "Test syn ROOT provisional class"],
      definition: ["Test definition for Prov Class ROOT"],
      ontology: @@ontologies[0]
    })
    @@test_pc_root.save

    @@cls_uri = RDF::URI.new("http://bioontology.org/ontologies/ResearchArea.owl#Area_of_Research")
    # Create a test CHILD provisional class
    @@test_pc_child = LinkedData::Models::ProvisionalClass.new({
      creator: @@test_user,
      label: "Provisional Class - CHILD",
      synonym: ["Test synonym for Prov Class CHILD", "Test syn CHILD provisional class"],
      definition: ["Test definition for Prov Class CHILD"],
      ontology: @@ontologies[0],
      subclassOf: @@cls_uri
    })
    @@test_pc_child.save
  end

  def self.after_suite
    @@test_pc_root.delete
    @@test_pc_child.delete
    LinkedData::SampleData::Ontology.delete_ontologies_and_submissions
    @@test_user.delete
    LinkedData::Models::Ontology.indexClear
    LinkedData::Models::Ontology.indexCommit
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
    acronym = "MCCLSEARCHTEST-0"
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
    acronym = "MCCLSEARCHTEST-0"
    get "/search?q=receptor%20antagonists&ontologies=#{acronym}&require_exact_match=true"
    assert last_response.ok?
    results = MultiJson.load(last_response.body)
    assert_equal 1, results["collection"].length

    get "search?q=data&require_definitions=true"
    assert last_response.ok?
    results = MultiJson.load(last_response.body)
    assert_equal 26, results["collection"].length

    get "search?q=data&require_definitions=false"
    assert last_response.ok?
    results = MultiJson.load(last_response.body)
    assert results["collection"].length > 26

    # testing "also_search_obsolete" flag
    acronym = "BROSEARCHTEST-0"

    get "search?q=Integration%20and%20Interoperability&ontologies=#{acronym}"
    results = MultiJson.load(last_response.body)
    assert_equal 22, results["collection"].length

    get "search?q=Integration%20and%20Interoperability&ontologies=#{acronym}&also_search_obsolete=false"
    results = MultiJson.load(last_response.body)
    assert_equal 22, results["collection"].length

    get "search?q=Integration%20and%20Interoperability&ontologies=#{acronym}&also_search_obsolete=true"
    results = MultiJson.load(last_response.body)
    assert_equal 29, results["collection"].length

    # testing "subtree_root_id" parameter
    get "search?q=training&ontologies=#{acronym}"
    results = MultiJson.load(last_response.body)
    assert_equal 3, results["collection"].length

    get "search?q=training&ontology=#{acronym}&subtree_root_id=http%3A%2F%2Fbioontology.org%2Fontologies%2FActivity.owl%23Activity"
    results = MultiJson.load(last_response.body)
    assert_equal 1, results["collection"].length

    # testing cui and semantic_types flags
    get "search?q=Funding%20Resource&ontologies=#{acronym}&include=prefLabel,synonym,definition,notation,cui,semanticType"
    results = MultiJson.load(last_response.body)
    assert_equal 35, results["collection"].length
    assert_equal "Funding Resource", results["collection"][0]["prefLabel"]
    assert_equal "T028", results["collection"][0]["semanticType"][0]
    assert_equal "X123456", results["collection"][0]["cui"][0]

    get "search?q=Funding&ontologies=#{acronym}&include=prefLabel,synonym,definition,notation,cui,semanticType&cui=X123456"
    results = MultiJson.load(last_response.body)
    assert_equal 1, results["collection"].length
    assert_equal "X123456", results["collection"][0]["cui"][0]

    get "search?q=Funding&ontologies=#{acronym}&include=prefLabel,synonym,definition,notation,cui,semanticType&semanticType=T028"
    results = MultiJson.load(last_response.body)
    assert_equal 5, results["collection"].length
    assert_equal "T028", results["collection"][0]["semanticType"][0]
  end

  def test_wildcard_search
    get "/search?q=lun*"
    assert last_response.ok?
    results = MultiJson.load(last_response.body)
    coll = results["collection"]
  end

  def test_search_provisional_class
    acronym = "BROSEARCHTEST-0"
    ontology_type = "VALUE_SET_COLLECTION"
    # roots only with provisional class test
    get "search?also_search_provisional=true&valueset_roots_only=true&ontology_types=#{ontology_type}&ontologies=#{acronym}"
    results = MultiJson.load(last_response.body)
    assert_equal 10, results["collection"].length
    provisional = results["collection"].select {|res| assert_equal ontology_type, res["ontologyType"]; res["provisional"]}
    assert_equal 1, provisional.length
    assert_equal @@test_pc_root.label, provisional[0]["prefLabel"]

    # subtree root with provisional class test
    get "search?ontology=#{acronym}&subtree_root_id=#{CGI::escape(@@cls_uri.to_s)}&also_search_provisional=true"
    results = MultiJson.load(last_response.body)
    assert_equal 21, results["collection"].length
    provisional = results["collection"].select {|res| res["provisional"]}
    assert_equal 1, provisional.length
    assert_equal @@test_pc_child.label, provisional[0]["prefLabel"]
  end

end
