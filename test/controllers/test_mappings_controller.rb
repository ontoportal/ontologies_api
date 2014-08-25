require_relative '../test_case'

class TestMappingsController < TestCase

  def self.before_suite

    ["BRO-TEST-MAP-0","CNO-TEST-MAP-0","FAKE-TEST-MAP-0"].each do |acr|
      LinkedData::Models::OntologySubmission.where(ontology: [acronym: acr]).to_a.each do |s|
        s.delete
      end
      ont = LinkedData::Models::Ontology.find(acr).first
      if ont
        ont.delete
      end
    end
    LinkedData::SampleData::Ontology.create_ontologies_and_submissions({
      process_submission: true,
      acronym: "BRO-TEST-MAP",
      name: "BRO-TEST-MAP",
      file_path: "./test/data/ontology_files/BRO_v3.2.owl",
      ont_count: 1,
      submission_count: 1
    })
    LinkedData::SampleData::Ontology.create_ontologies_and_submissions({
      process_submission: true,
      acronym: "CNO-TEST-MAP",
      name: "CNO-TEST-MAP",
      file_path: "./test/data/ontology_files/CNO_05.owl",
      ont_count: 1,
      submission_count: 1
    })
    LinkedData::SampleData::Ontology.create_ontologies_and_submissions({
      process_submission: true,
      acronym: "FAKE-TEST-MAP",
      name: "FAKE-TEST-MAP",
      file_path: "./test/data/ontology_files/fake_for_mappings.owl",
      ont_count: 1,
      submission_count: 1
    })
  end

  def test_mappings_for_ontology
    ontology = "BRO-TEST-MAP-0"
    get "/ontologies/#{ontology}/mappings"
    assert last_response.ok?
    mappings = MultiJson.load(last_response.body)

    #pages
    assert mappings["page"] == 1
    assert mappings["pageCount"] == 1
    assert mappings["prevPage"] == nil
    assert mappings["nextPage"] == nil

    assert_equal 18, mappings["collection"].length
    mappings = mappings["collection"]

    mappings.each do |mapping|
      assert mapping["classes"].length, 2
      origin = nil
      mapping["classes"].each do |c|
        assert c["@type"]["owl#Class"] != nil
        assert c["links"] != nil
        assert c["links"]["ontology"] != nil
        if c["links"]["ontology"][ontology] != nil
          origin = c["@id"]
        end
      end
      #Linked data already tests for correct mappings
      #in API we just need to test for the data structure
      assert origin != nil
    end
  end

  def test_mappings_between_ontologies
    bro_uri = LinkedData::Models::Ontology.find("BRO-TEST-MAP-0").first.id.to_s
    fake_uri = LinkedData::Models::Ontology.find("FAKE-TEST-MAP-0").first.id.to_s
    ontologies_params = [
      "BRO-TEST-MAP-0,FAKE-TEST-MAP-0",
      "#{bro_uri},#{fake_uri}",
    ]
    ontologies_params.each do |ontologies|
      ont1, ont2 = ontologies.split(",")
      get "/mappings/?ontologies=#{ontologies}"
      assert last_response.ok?
      mappings = MultiJson.load(last_response.body)
      #pages
      assert mappings["page"] == 1
      assert mappings["pageCount"] == 1
      assert mappings["prevPage"] == nil
      assert mappings["nextPage"] == nil

      assert_equal 8, mappings["collection"].length
      mappings = mappings["collection"]
      mappings.each do |mapping|
        assert mapping["classes"].length, 2
        mapping["classes"].each do |c|
          assert c["@type"]["owl#Class"] != nil
          assert c["links"] != nil
          assert c["links"]["ontology"] != nil

          class_ont = c["links"]["ontology"]
          assert class_ont[ont1] != nil || class_ont[ont2] != nil
        end
      end
    end
  end

  def test_mappings_for_ontology_pages
    ontology = "BRO-TEST-MAP-0"
    pagesize = 4
    page = 1
    next_page = nil
    total = 0
    begin
      get "/ontologies/#{ontology}/mappings?pagesize=#{pagesize}&page=#{page}"
      assert last_response.ok?
      mappings = MultiJson.load(last_response.body)
      #pages
      assert mappings["page"] == page
      assert mappings["pageCount"] == 5
      assert_equal (page == 5 ? 2 : 4), mappings["collection"].length
      assert mappings["pageCount"] == 5
      assert mappings["prevPage"] == (page > 1 ? page - 1 : nil)
      assert mappings["nextPage"] == (page < 5 ? page + 1 : nil)
      next_page = mappings["nextPage"]
      mappings = mappings["collection"]
      total += mappings.length
      page = next_page
    end while (next_page)
    assert total == 18
  end

  def test_mappings
    #not supported
    get '/mappings'
    assert !last_response.ok?
  end

  def test_get_single_mapping
    #not supported
    get "/mappings/some_fake_id"
    assert !last_response.ok?
  end

  def test_create_mapping

    mapping_term_a = ["http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Image_Algorithm",
      "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Image",
      "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Integration_and_Interoperability_Tools" ]
    mapping_ont_a = ["BRO-TEST-MAP-0","BRO-TEST-MAP-0","BRO-TEST-MAP-0"]


    mapping_term_b = ["http://purl.org/incf/ontology/Computational_Neurosciences/cno_alpha.owl#cno_0000202",
      "http://purl.org/incf/ontology/Computational_Neurosciences/cno_alpha.owl#cno_0000203",
      "http://purl.org/incf/ontology/Computational_Neurosciences/cno_alpha.owl#cno_0000205" ]
    mapping_ont_b = ["CNO-TEST-MAP-0","CNO-TEST-MAP-0","CNO-TEST-MAP-0"]

    relations = [ "http://www.w3.org/2004/02/skos/core#exactMatch",
                  "http://www.w3.org/2004/02/skos/core#closeMatch",
                  "http://www.w3.org/2004/02/skos/core#relatedMatch" ]

    3.times do |i|
      classes = {}
      classes[mapping_term_a[i]] = mapping_ont_a[i]
      classes[mapping_term_b[i]] = mapping_ont_b[i]

      mapping = { classes: classes,
                  comment: "comment for mapping test #{i}",
                  relation: relations[i],
                  creator: "http://data.bioontology.org/users/tim"
      }

      post "/mappings/", 
            MultiJson.dump(mapping), 
            "CONTENT_TYPE" => "application/json"

      assert last_response.status == 201
      response = MultiJson.load(last_response.body)
      assert response["process"]["comment"] == "comment for mapping test #{i}"
      assert response["process"]["creator"]["users/tim"]
      assert response["process"]["relation"] == relations[i]
      assert response["process"]["date"] != nil
      response["classes"].each do |cls|
        if cls["links"]["ontology"].split("/")[-1] == mapping_ont_a[i]
          assert cls["@id"] == mapping_term_a[i]
        elsif cls["links"]["ontology"].split("/")[-1] == mapping_ont_b[i]
          assert cls["@id"] == mapping_term_b[i]
        else
          assert 1==0, "uncontrolled mapping response in post"
        end
      end
      sleep(1.2) # to ensure different in times in dates. Later test on recent mappings
    end

    get "/mappings/recent/"
    assert last_response.status == 200
    response = MultiJson.load(last_response.body)
    assert (response.length == 5)
    date = nil
    response.each do |x|
      assert x["classes"].length == 2
      assert x["process"] != nil
      date_x = DateTime.iso8601(x["process"]["date"])
      if date
        assert date >= date_x
      end
      date = date_x
    end
  end

  def test_delete_mapping
    mapping_term_a = ["http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Pattern_Recognition",
      "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Pattern_Inference_Algorithm",
      "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Pattern_Inference_Algorithm" ]
    mapping_ont_a = ["BRO-TEST-MAP-0","BRO-TEST-MAP-0","BRO-TEST-MAP-0"]


    mapping_term_b = ["http://purl.org/incf/ontology/Computational_Neurosciences/cno_alpha.owl#cno_0000202",
      "http://purl.org/incf/ontology/Computational_Neurosciences/cno_alpha.owl#cno_0000203",
      "http://purl.org/incf/ontology/Computational_Neurosciences/cno_alpha.owl#cno_0000203" ]
    mapping_ont_b = ["CNO-TEST-MAP-0","CNO-TEST-MAP-0","CNO-TEST-MAP-0"]

    relations = [ "http://www.w3.org/2004/02/skos/core#exactMatch",
                  "http://www.w3.org/2004/02/skos/core#closeMatch",
                  "http://www.w3.org/2004/02/skos/core#relatedMatch" ]

    3.times do |i|
      terms = []
      terms << { ontology: mapping_ont_a[i], term: [mapping_term_a[i]] }
      terms << { ontology: mapping_ont_b[i], term: [mapping_term_b[i]] }
      mapping = { terms: terms,
                  comment: "comment for mapping test #{i}",
                  relation: relations[i],
                  creator: "http://data.bioontology.org/users/tim"
      }
      post "/mappings/", MultiJson.dump(mapping), "CONTENT_TYPE" => "application/json"
      assert last_response.status == 201
      response = MultiJson.load(last_response.body)
      mapping_id = CGI.escape(response["@id"])
      delete "/mappings/#{mapping_id}"
      assert last_response.status == 204
      get "/mappings/#{mapping_id}"
      assert last_response.status == 404
    end

    #delete a loom mapping
    #nothing should happen
    LinkedData::Models::Mapping.all.each do |m|
      m_id = CGI.escape(m.id.to_s)
      get "/mappings/#{m_id}"
      assert last_response.status == 200
      mapping = MultiJson.load(last_response.body)
      if mapping["process"].select { |x| x["name"] == "REST Mapping" }.length >  0
        next #skip manual mappings
      end
      delete "/mappings/#{m_id}"
      assert last_response.status == 400
      get "/mappings/#{m_id}"
      assert last_response.status == 200
      break #one is enough for testing
    end

  end

  def test_mappings_statistics
    get "/mappings/statistics/ontologies/"
    assert last_response.ok?
    stats = MultiJson.load(last_response.body)
    data = {"BRO-TEST-MAP-0"=>20,
            "CNO-TEST-MAP-0"=>19,
            "FAKE-TEST-MAP-0"=>21}
    assert_equal data, stats
    data.each_key do |acr|
          mappings_acr = LinkedData::Models::Mapping
            .where(terms: [
              ontology: LinkedData::Models::Ontology.find(acr).first
                          ]).all
          assert mappings_acr.count == data[acr]
    end
  end

  def test_mappings_statistics_for_ontology
    ontology = "BRO-TEST-MAP-0"
    get "/mappings/statistics/ontologies/#{ontology}"
    assert last_response.ok?
    stats = MultiJson.load(last_response.body)
    assert_equal 9, stats["CNO-TEST-MAP-0"]
    assert_equal 11, stats["FAKE-TEST-MAP-0"]
    stats.each_key do |acr|
          mappings_acr = LinkedData::Models::Mapping
            .where(terms: [
              ontology:
              LinkedData::Models::Ontology.find("BRO-TEST-MAP-0").first
                          ])
            .and(terms: [ontology:
              LinkedData::Models::Ontology.find(acr).first
                          ])
            .all
          assert mappings_acr.count == stats[acr]
    end
    ontology = "FAKE-TEST-MAP-0"
    get "/mappings/statistics/ontologies/#{ontology}"
    assert last_response.ok?
    stats = MultiJson.load(last_response.body)
    assert_equal 11, stats["BRO-TEST-MAP-0"]
    assert_equal 10, stats["CNO-TEST-MAP-0"]
  end

end
