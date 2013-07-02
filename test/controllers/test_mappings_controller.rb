require_relative '../test_case'

class TestMappingsController < TestCase

  def self.before_suite

    ["BRO-TEST-MAP","CNO-TEST-MAP","FAKE-TEST-MAP"].each do |acr|
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

  def test_mappings_for_class
    ontology = "BRO-TEST-MAP"
    cls = "http://bioontology.org/ontologies/Activity.owl#IRB"
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
