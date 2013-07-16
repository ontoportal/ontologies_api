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
      process.new(fake,cno,Logger.new(STDOUT)).start()
      process.new(fake,bro,Logger.new(STDOUT)).start()
      process.new(bro,cno,Logger.new(STDOUT)).start()
    end
  end

  def certify_mapping(mapping)
    procs = 0
    if mapping["terms"].map { |x| x["term"]}.flatten.uniq.length == 1
      assert mapping["process"].length == 1
      assert (mapping["process"].map { |x| x["name"] }.index "same_uris") != nil
      procs += 1
    end
    labels = []
    syns = []
    cuis = []
    mapping["terms"].each do |term|
      s = LinkedData::Models::Ontology.find(RDF::URI.new(term["ontology"])).first
                .latest_submission
      c = LinkedData::Models::Class.find(RDF::URI.new(term["term"].first)).in(s)
                               .include(:prefLabel,:synonym, :cui)
                               .first
      assert c
      cuis << c.cui if c.cui
      labels << transmform_literal(c.prefLabel)
      syns << c.synonym.map { |x| transmform_literal(x) }
    end
    if cuis.length == 2 && cuis.uniq.length == 1
      assert (mapping["process"].map { |x| x["name"] }.index "cui") != nil
      procs += 1
    end
    if labels.length == 2 && labels.uniq.length == 1
      if mapping["terms"].map { |x| x["term"]}.flatten.uniq.length > 1
        assert (mapping["process"].map { |x| x["name"] }.index "loom") != nil
        procs += 1
      end
    elsif syns[0].index(labels[1]) || syns[1].index(labels[0])
      if mapping["terms"].map { |x| x["term"]}.flatten.uniq.length > 1
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
    assert mappings.length == 2
    mapped_to = []
    mapped_to_data= ["http://www.semanticweb.org/manuelso/ontologies/mappings/fake/federalf",
       "http://purl.org/incf/ontology/Computational_Neurosciences/cno_alpha.owl#cno_0000160"].sort

    mappings.each do |mapping|
      assert mapping["process"].first["name"] == "cui"
      mapping["terms"].each do |term|
        if term["term"] == ["http://bioontology.org/ontologies/Activity.owl#IRB"]
          assert term["ontology"] == "http://data.bioontology.org/ontologies/BRO-TEST-MAP-0"
        end
        if term["term"] == ["http://www.semanticweb.org/manuelso/ontologies/mappings/fake/federalf"]
          assert term["ontology"] == "http://data.bioontology.org/ontologies/FAKE-TEST-MAP-0"
          mapped_to << term["term"]
        end
        if term["term"] ==
          ["http://purl.org/incf/ontology/Computational_Neurosciences/cno_alpha.owl#cno_0000160"]
          assert term["ontology"] == "http://data.bioontology.org/ontologies/CNO-TEST-MAP-0"
          mapped_to << term["term"]
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
    ontology = "BRO-TEST-MAP-0"
    get "/ontologies/#{ontology}/mappings"
    assert last_response.ok?
    mappings = MultiJson.load(last_response.body)

    #pages
    assert mappings["page"] == 1
    assert mappings["pageCount"] == 1
    assert mappings["prevPage"] == nil
    assert mappings["nextPage"] == nil

    assert mappings["collection"].length == 20
    mappings = mappings["collection"]

    mappings.each do |mapping|
      certify_mapping(mapping)
    end
  end

  def test_mappings_between_ontologies
    ontologies = "BRO-TEST-MAP-0,FAKE-TEST-MAP-0"
    get "/mappings/?ontologies=#{ontologies}"
    assert last_response.ok?
    mappings = MultiJson.load(last_response.body)
    #pages
    assert mappings["page"] == 1
    assert mappings["pageCount"] == 1
    assert mappings["prevPage"] == nil
    assert mappings["nextPage"] == nil

    assert mappings["collection"].length == 11
    mappings = mappings["collection"]

    mappings.each do |mapping|
      certify_mapping(mapping)
    end
  end

  def test_mappings_for_ontology_pages
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
      assert mappings["pageCount"] == 4
      assert mappings["prevPage"] == (page > 1 ? page -1 : nil)
      assert mappings["nextPage"] == (page < 4 ? page + 1 : nil)
      next_page = mappings["nextPage"]
      assert mappings["collection"].length == (page == 4 ? 2 : 6)
      mappings = mappings["collection"]
      mappings.each do |mapping|
        certify_mapping(mapping)
      end
      page = next_page
    end while (next_page)
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

  def test_mappings_statistics
    get "/mappings/statistics/ontologies/"
    assert last_response.ok?
    stats = MultiJson.load(last_response.body)
    assert stats == {"BRO-TEST-MAP-0"=>20, "CNO-TEST-MAP-0"=>19, "FAKE-TEST-MAP-0"=>21}
  end

  def test_mappings_statistics_for_ontology
    ontology = "BRO-TEST-MAP-0"
    get "/mappings/statistics/ontologies/#{ontology}"
    assert last_response.ok?
    stats = MultiJson.load(last_response.body)
    assert stats == {"CNO-TEST-MAP-0"=>9, "FAKE-TEST-MAP-0"=>11}
    ontology = "FAKE-TEST-MAP-0"
    get "/mappings/statistics/ontologies/#{ontology}"
    assert last_response.ok?
    stats = MultiJson.load(last_response.body)
    assert stats == {"BRO-TEST-MAP-0"=>11, "CNO-TEST-MAP-0"=>10}
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
