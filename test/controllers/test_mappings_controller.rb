require_relative '../test_case'

class TestMappingsController < TestCase

  def self.before_suite

    LinkedData::Models::TermMapping.all.each do |m|
      m.delete
    end
    LinkedData::Models::Mapping.all.each do |m|
      m.delete
    end
    LinkedData::Models::MappingProcess.all.each do |m|
      m.delete
    end

    ["BRO-TEST-MAP-0","CNO-TEST-MAP-0","FAKE-TEST-MAP-0"].each do |acr|
      LinkedData::Models::OntologySubmission.where(ontology: [acronym: acr]).to_a.each do |s|
        s.delete
      end
      ont = LinkedData::Models::Ontology.find(acr).first
      if ont
        ont.delete
      end
    end
    bro_count, bro_acros, bro =
      LinkedData::SampleData::Ontology.create_ontologies_and_submissions({
      process_submission: true,
      acronym: "BRO-TEST-MAP",
      name: "BRO-TEST-MAP",
      file_path: "./test/data/ontology_files/BRO_v3.2.owl",
      ont_count: 1,
      submission_count: 1
    })
    cno_count, cno_acronyms, cno =
      LinkedData::SampleData::Ontology.create_ontologies_and_submissions({
      process_submission: true,
      acronym: "CNO-TEST-MAP",
      name: "CNO-TEST-MAP",
      file_path: "./test/data/ontology_files/CNO_05.owl",
      ont_count: 1,
      submission_count: 1
    })
    fake_count, fake_acronyms, fake =
      LinkedData::SampleData::Ontology.create_ontologies_and_submissions({
      process_submission: true,
      acronym: "FAKE-TEST-MAP",
      name: "FAKE-TEST-MAP",
      file_path: "./test/data/ontology_files/fake_for_mappings.owl",
      ont_count: 1,
      submission_count: 1
    })


    mappings = [LinkedData::Mappings::CUI,
             LinkedData::Mappings::SameURI,
             LinkedData::Mappings::Loom]

    fake = fake.first
    cno = cno.first
    bro = bro .first
    mappings.each do |process|
      begin
        tmp_log = Logger.new(TestLogFile.new)
        process.new(fake,cno,tmp_log).start()
        process.new(fake,bro,tmp_log).start()
        process.new(bro,cno,tmp_log).start()
      rescue Exception => e
        puts "Error, logged in #{tmp_log.instance_variable_get("@logdev").dev.path}"
        raise e
      end

    end
  end

  def delete_manual_mapping
    manual_mapping = LinkedData::Models::Mapping.where(process: [name: "REST Mapping"])
                               .include(process: [:name])
                               .all
    manual_mapping.each do |m|
      m.process.each do |p|
        updated = LinkedData::Mappings.disconnect_mapping_process(m.id,p)
        if updated.process.length == 0
          LinkedData::Mappings.delete_mapping(m)
        end
      end
    end
  end

  def certify_mapping(mapping)
    procs = 0
    if mapping["classes"].map { |x| x["@id"] }.flatten.uniq.length == 1
      assert mapping["process"].length == 1
      assert (mapping["process"].map { |x| x["name"] }.index "same_uris") != nil
      procs += 1
    end
    labels = []
    syns = []
    cuis = []
    mapping["classes"].each do |term|
      ont_acr = term["links"]["ontology"].split("/")[-1]
      s = LinkedData::Models::Ontology.find(ont_acr).first
                .latest_submission
      c = LinkedData::Models::Class.find(RDF::URI.new(term["@id"])).in(s)
                               .include(:prefLabel,:synonym, :cui)
                               .first
      assert c
      cuis += c.cui if c.cui
      labels << transmform_literal(c.prefLabel)
      syns << c.synonym.map { |x| transmform_literal(x) }
    end
    if cuis.length == 2 && cuis.uniq.length == 1
      assert (mapping["process"].map { |x| x["name"] }.index "cui") != nil
      procs += 1
    end
    if labels.length == 2 && labels.uniq.length == 1
      if mapping["classes"].map { |x| x["@id"] }.flatten.uniq.length > 1
        processes = mapping["process"].map { |x| x["name"] }
        assert processes.index("loom") != nil || processes.index("cui") != nil
        procs += 1
      end
    elsif syns[0].index(labels[1]) || syns[1].index(labels[0])
      if mapping["classes"].map { |x| x["@id"] }.flatten.uniq.length > 1
        assert (mapping["process"].map { |x| x["name"] }.index "loom") != nil
        procs += 1
      end
    end
    assert procs > 0
  end

  def test_mappings_for_class
    ontology = "BRO-TEST-MAP-0"
    cls = "http://bioontology.org/ontologies/Activity.owl#IRB"
    cls= CGI.escape(cls)
    get "/ontologies/#{ontology}/classes/#{cls}/mappings"
    assert last_response.ok?
    mappings = MultiJson.load(last_response.body)
    assert_equal 2, mappings.length
    mapped_to = []
    mapped_to_data= ["http://www.semanticweb.org/manuelso/ontologies/mappings/fake/federalf",
       "http://purl.org/incf/ontology/Computational_Neurosciences/cno_alpha.owl#cno_0000160"].sort

    mappings.each do |mapping|
      assert mapping["process"].first["name"] == "cui"
      mapping["classes"].each do |cls|
        if cls["@id"] == "http://bioontology.org/ontologies/Activity.owl#IRB"
          assert cls["links"]["ontology"].split("/").last == "BRO-TEST-MAP-0"
        end
        if cls["@id"] == "http://www.semanticweb.org/manuelso/ontologies/mappings/fake/federalf"
          assert cls["links"]["ontology"].split("/").last == "FAKE-TEST-MAP-0"
          mapped_to << cls["@id"]
        end
        if cls["@id"] == "http://purl.org/incf/ontology/Computational_Neurosciences/cno_alpha.owl#cno_0000160"
          assert cls["links"]["ontology"].split("/").last == "CNO-TEST-MAP-0"
          mapped_to << cls["@id"]
        end
      end
    end
    assert mapped_to_data == mapped_to.flatten.sort
  end


  # NOTE: this is the loom transform literal to test round trip mappings
  # This needs to be changed if equivalent function is changed in:
  # LinkedData::Mappings:::Loom
  def transmform_literal(lit)
    res = []
    lit.each_char do |c|
      if (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
        res << c.downcase
      end
    end
    return res.join ''
  end

  def test_mappings_for_ontology
    delete_manual_mapping()
    ontology = "BRO-TEST-MAP-0"
    get "/ontologies/#{ontology}/mappings"
    assert last_response.ok?
    mappings = MultiJson.load(last_response.body)

    #pages
    assert mappings["page"] == 1
    assert mappings["pageCount"] == 1
    assert mappings["prevPage"] == nil
    assert mappings["nextPage"] == nil

    assert_equal 20, mappings["collection"].length
    mappings = mappings["collection"]

    mappings.each do |mapping|
      certify_mapping(mapping)
    end
  end

  def test_mappings_between_ontologies
    delete_manual_mapping()
    bro_uri = LinkedData::Models::Ontology.find("BRO-TEST-MAP-0").first.id.to_s
    fake_uri = LinkedData::Models::Ontology.find("FAKE-TEST-MAP-0").first.id.to_s
    ontologies_params = [
      "BRO-TEST-MAP-0,FAKE-TEST-MAP-0",
      "#{bro_uri},#{fake_uri}",
    ]
    ontologies_params.each do |ontologies|
      get "/mappings/?ontologies=#{ontologies}"
      assert last_response.ok?
      mappings = MultiJson.load(last_response.body)
      #pages
      assert mappings["page"] == 1
      assert mappings["pageCount"] == 1
      assert mappings["prevPage"] == nil
      assert mappings["nextPage"] == nil

      assert_equal 11, mappings["collection"].length
      mappings = mappings["collection"]

      mappings.each do |mapping|
        certify_mapping(mapping)
      end
    end
  end

  def test_mappings_for_ontology_pages
    delete_manual_mapping()
    ontology = "BRO-TEST-MAP-0"
    pagesize = 6
    page = 1
    next_page = nil
    begin
      get "/ontologies/#{ontology}/mappings?pagesize=#{pagesize}&page=#{page}"
      assert last_response.ok?
      mappings = MultiJson.load(last_response.body)
      #pages
      assert mappings["page"] == page
      assert_equal (page == 4 ? 2 : 6), mappings["collection"].length
      assert mappings["pageCount"] == 4
      assert mappings["prevPage"] == (page > 1 ? page - 1 : nil)
      assert mappings["nextPage"] == (page < 4 ? page + 1 : nil)
      next_page = mappings["nextPage"]
      mappings = mappings["collection"]
      mappings.each do |mapping|
        certify_mapping(mapping)
      end
      page = next_page
    end while (next_page)
  end

  def test_mappings
    #not supported
    get '/mappings'
    assert !last_response.ok?
  end

  def test_get_single_mapping
    count = 0
    LinkedData::Models::Mapping.all.each do |m|
      m_id = CGI.escape(m.id.to_s)
      get "/mappings/#{m_id}"
      assert last_response.status == 200
      mapping = MultiJson.load(last_response.body)
      if mapping["process"].select { |x| x["name"] == "REST Mapping" }.length > 0
        next #skip manual mappings
      end
      certify_mapping(mapping)
      count += 1
    end
    assert count > 10
  end

  def test_create_mapping
    delete_manual_mapping

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
      assert response["process"].first["comment"] == "comment for mapping test #{i}"
      assert response["process"].first["creator"]["users/tim"]
      assert response["process"].first["relation"] == relations[i]
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

    #repeating the process should always bring two processes per mapping
    terms = []
    terms << { ontology: mapping_ont_a[2], term: [mapping_term_a[2]] }
    terms << { ontology: mapping_ont_b[2], term: [mapping_term_b[2]] }
    mapping = { terms: terms,
                comment: "comment for mapping test XX",
                relation: "http://bogus.relation.com/predicate",
                creator: "http://data.bioontology.org/users/tim" }
    n = LinkedData::Models::Mapping.where.count
    post "/mappings/", MultiJson.dump(mapping), "CONTENT_TYPE" => "application/json"

    #number of mappings does not change only process has been added
    assert n == LinkedData::Models::Mapping.where.count

    assert last_response.status == 201
    response = MultiJson.load(last_response.body)
    assert response["process"].length > 1
    response["process"].select { |x| x["relation"] == "http://bogus.relation.com/predicate" }.length > 0

    #recent mappings can be tested here
    rest_mappings = LinkedData::Models::Mapping.where.include(process: [:date]).all
                        .select { |x| x.process.first.date }
    get "/mappings/recent/"
    assert last_response.status == 200
    response = MultiJson.load(last_response.body)
    assert (response.length == 4)
    date = nil
    response.each do |x|
      assert rest_mappings.map { |x| x.id.to_s.split("/")[-1] }
                  .include?(response.first["@id"].to_s.split("/")[-1])
      date_x = DateTime.iso8601(response.first["process"].first["date"])
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
    delete_manual_mapping()
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
    delete_manual_mapping()
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
