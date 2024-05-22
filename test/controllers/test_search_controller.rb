require_relative '../test_case'

class TestSearchController < TestCase

  def self.before_suite
    LinkedData::Models::Ontology.indexClear
    LinkedData::Models::Agent.indexClear
    LinkedData::Models::Class.indexClear
    LinkedData::Models::OntologyProperty.indexClear

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
    LinkedData::Models::Agent.indexClear
    LinkedData::Models::Class.indexClear
    LinkedData::Models::OntologyProperty.indexClear
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
    assert_equal "cell line", doc["prefLabel"].first
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
    assert results["collection"].all? {|doc| !doc["definition"].nil? && doc.values.flatten.join(" ").include?("data") }
    #assert_equal 26, results["collection"].length

    get "search?q=data&require_definitions=false"
    assert last_response.ok?
    results = MultiJson.load(last_response.body)
    assert results["collection"].length > 26

    # testing "also_search_obsolete" flag
    acronym = "BROSEARCHTEST-0"

    get "search?q=Integration%20and%20Interoperability&ontologies=#{acronym}"
    results = MultiJson.load(last_response.body)

    assert results["collection"].all? { |x| !x["obsolete"] }
    count = results["collection"].length

    get "search?q=Integration%20and%20Interoperability&ontologies=#{acronym}&also_search_obsolete=false"
    results = MultiJson.load(last_response.body)
    assert_equal count, results["collection"].length

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
    #assert_equal 35, results["collection"].length
    assert results["collection"].all? do |r|
      ["prefLabel", "synonym", "definition", "notation", "cui", "semanticType"].map {|x| r[x]}
                                                                               .flatten
                                                                               .join(' ')
                                                                               .include?("Funding Resource")
    end
    assert_equal "Funding Resource", results["collection"][0]["prefLabel"].first
    assert_equal "T028", results["collection"][0]["semanticType"][0]
    assert_equal "X123456", results["collection"][0]["cui"][0]

    get "search?q=Funding&ontologies=#{acronym}&include=prefLabel,synonym,definition,notation,cui,semanticType&cui=X123456"
    results = MultiJson.load(last_response.body)
    assert_equal 1, results["collection"].length
    assert_equal "X123456", results["collection"][0]["cui"][0]

    get "search?q=Funding&ontologies=#{acronym}&include=prefLabel,synonym,definition,notation,cui,semanticType&semantic_types=T028"
    results = MultiJson.load(last_response.body)
    assert_equal 1, results["collection"].length
    assert_equal "T028", results["collection"][0]["semanticType"][0]
  end

  def test_subtree_search
    acronym = "BROSEARCHTEST-0"
    class_id = RDF::IRI.new "http://bioontology.org/ontologies/Activity.owl#Activity"
    pc1 = LinkedData::Models::ProvisionalClass.new({label: "Test Provisional Parent for Training", subclassOf: class_id, creator: @@test_user, ontology: @@ontologies[0]})
    pc1.save
    pc2 = LinkedData::Models::ProvisionalClass.new({label: "Test Provisional Leaf for Training", subclassOf: pc1.id, creator: @@test_user, ontology: @@ontologies[0]})
    pc2.save

    get "search?q=training&ontology=#{acronym}&subtree_root_id=#{CGI.escape(class_id.to_s)}"
    results = MultiJson.load(last_response.body)
    assert_equal 1, results["collection"].length

    get "search?q=training&ontology=#{acronym}&subtree_root_id=#{CGI.escape(class_id.to_s)}&also_search_provisional=true"
    results = MultiJson.load(last_response.body)
    assert_equal 3, results["collection"].length

    pc2.delete
    pc2 = LinkedData::Models::ProvisionalClass.find(pc2.id).first
    assert_nil pc2
    pc1.delete
    pc1 = LinkedData::Models::ProvisionalClass.find(pc1.id).first
    assert_nil pc1
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
    assert_includes [10, 6], results["collection"].length # depending if owlapi import SKOS concepts
    provisional = results["collection"].select {|res| assert_equal ontology_type, res["ontologyType"]; res["provisional"]}
    assert_equal 1, provisional.length
    assert_equal @@test_pc_root.label, provisional[0]["prefLabel"].first

    # subtree root with provisional class test
    get "search?ontology=#{acronym}&subtree_root_id=#{CGI::escape(@@cls_uri.to_s)}&also_search_provisional=true"
    results = MultiJson.load(last_response.body)
    assert_equal 20, results["collection"].length

    provisional = results["collection"].select {|res| res["provisional"]}
    assert_equal 1, provisional.length
    assert_equal @@test_pc_child.label, provisional[0]["prefLabel"].first
  end

  def test_multilingual_search
    get "/search?q=Activity&ontologies=BROSEARCHTEST-0"
    res =  MultiJson.load(last_response.body)
    refute_equal 0, res["totalCount"]

    doc = res["collection"].select{|doc| doc["@id"].to_s.eql?('http://bioontology.org/ontologies/Activity.owl#Activity')}.first
    refute_nil doc

    res = LinkedData::Models::Class.search("prefLabel_none:Activity", {:fq => "submissionAcronym:BROSEARCHTEST-0", :start => 0, :rows => 80})
    refute_equal 0, res["response"]["numFound"]
    refute_nil res["response"]["docs"].select{|doc| doc["resource_id"].eql?('http://bioontology.org/ontologies/Activity.owl#Activity')}.first

    get "/search?q=Activit%C3%A9&ontologies=BROSEARCHTEST-0&lang=fr"
    res =  MultiJson.load(last_response.body)
    refute_equal 0, res["totalCount"]
    refute_nil res["collection"].select{|doc| doc["@id"].eql?('http://bioontology.org/ontologies/Activity.owl#Activity')}.first



    get "/search?q=ActivityEnglish&ontologies=BROSEARCHTEST-0&lang=en"
    res =  MultiJson.load(last_response.body)
    refute_equal 0, res["totalCount"]
    refute_nil res["collection"].select{|doc| doc["@id"].eql?('http://bioontology.org/ontologies/Activity.owl#Activity')}.first


    get "/search?q=ActivityEnglish&ontologies=BROSEARCHTEST-0&lang=fr&require_exact_match=true"
    res =  MultiJson.load(last_response.body)
    assert_nil res["collection"].select{|doc| doc["@id"].eql?('http://bioontology.org/ontologies/Activity.owl#Activity')}.first

    get "/search?q=ActivityEnglish&ontologies=BROSEARCHTEST-0&lang=en&require_exact_match=true"
    res =  MultiJson.load(last_response.body)
    refute_nil res["collection"].select{|doc| doc["@id"].eql?('http://bioontology.org/ontologies/Activity.owl#Activity')}.first

    get "/search?q=Activity&ontologies=BROSEARCHTEST-0&lang=en&require_exact_match=true"
    res =  MultiJson.load(last_response.body)
    assert_nil res["collection"].select{|doc| doc["@id"].eql?('http://bioontology.org/ontologies/Activity.owl#Activity')}.first

    get "/search?q=Activit%C3%A9&ontologies=BROSEARCHTEST-0&lang=fr&require_exact_match=true"
    res =  MultiJson.load(last_response.body)
    refute_nil res["collection"].select{|doc| doc["@id"].eql?('http://bioontology.org/ontologies/Activity.owl#Activity')}.first


  end


end
