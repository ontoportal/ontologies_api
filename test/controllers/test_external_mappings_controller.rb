require_relative '../test_case'

class TestExternalMappingsController < TestCase

  def self.before_suite
    ["BRO-TEST-MAP-0", "CNO-TEST-MAP-0", "FAKE-TEST-MAP-0"].each do |acr|
      LinkedData::Models::OntologySubmission.where(ontology: [acronym: acr]).to_a.each do |s|
        s.delete
      end
      ont = LinkedData::Models::Ontology.find(acr).first
      if ont
        ont.delete
      end
    end
    # indexing term is needed
    LinkedData::SampleData::Ontology.create_ontologies_and_submissions({
                                                                         process_submission: true,
                                                                         process_options: {process_rdf: true, extract_metadata: false, index_search: true},
                                                                         acronym: "BRO-TEST-MAP",
                                                                         name: "BRO-TEST-MAP",
                                                                         file_path: "./test/data/ontology_files/BRO_v3.2.owl",
                                                                         ont_count: 1,
                                                                         submission_count: 1
                                                                       })
    LinkedData::SampleData::Ontology.create_ontologies_and_submissions({
                                                                         process_submission: true,
                                                                         process_options: {process_rdf: true, extract_metadata: false},
                                                                         acronym: "CNO-TEST-MAP",
                                                                         name: "CNO-TEST-MAP",
                                                                         file_path: "./test/data/ontology_files/CNO_05.owl",
                                                                         ont_count: 1,
                                                                         submission_count: 1
                                                                       })
    LinkedData::SampleData::Ontology.create_ontologies_and_submissions({
                                                                         process_submission: true,
                                                                         process_options: {process_rdf: true, extract_metadata: false},
                                                                         acronym: "FAKE-TEST-MAP",
                                                                         name: "FAKE-TEST-MAP",
                                                                         file_path: "./test/data/ontology_files/fake_for_mappings.owl",
                                                                         ont_count: 1,
                                                                         submission_count: 1
                                                                       })
    NcboCron::Models::QueryWarmer.new(Logger.new(TestLogFile.new)).run
  end

  def test_mappings_controllers_in_order
    LinkedData::Models::RestBackupMapping.all.each do |m|
      LinkedData::Mappings.delete_rest_mapping(m.id)
    end
    delete_external_mappings
    delete_interportal_mappings

  end

  # Create and delete an external mapping
  def delete_external_mappings

    mapping = { classes: ['http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Knowledge_Extraction',
                          'http://www.movieontology.org/2009/10/01/movieontology.owl#Love'],
                "subject_source_id": 'http://bioontology.org/ontologies/BiomedicalResourceOntology.owl',
                "object_source_id": 'http://www.movieontology.org/2009/10/01/movieontology.owl',
                comment: "testing external mappings",
                relation: ["http://www.w3.org/2004/02/skos/core#exactMatch", "http://purl.org/linguistics/gold/translation"],
                name: 'test',
                creator: "tim"
    }

    post "/mappings/", MultiJson.dump(mapping), "CONTENT_TYPE" => "application/json"
    assert last_response.status == 201, "Error creating the external mapping: #{last_response.body}"

    response = MultiJson.load(last_response.body)
    assert response["process"]["comment"] == "testing external mappings"
    assert response["process"]["creator"]["users/tim"]
    assert response["process"]["relation"] == ["http://www.w3.org/2004/02/skos/core#exactMatch", "http://purl.org/linguistics/gold/translation"]
    assert response["process"]["date"] != nil

    # to check if the external mapping we wanted have been created
    mapping_created = false

    LinkedData::Models::RestBackupMapping.all.each do |m|
      m_id = CGI.escape(m.id.to_s)
      get "/mappings/#{m_id}"
      assert last_response.status == 200
      mapping = MultiJson.load(last_response.body)
      assert mapping["classes"].length == 2
      mapping["classes"].each do |cls|
        if cls["@id"].to_s == "http://www.movieontology.org/2009/10/01/movieontology.owl#Love"
          mapping_created = true
        end
      end

      assert mapping["process"] != nil
      delete "/mappings/#{m_id}"
      assert last_response.status == 204
      get "/mappings/#{m_id}"
      assert last_response.status == 404
    end
    assert mapping_created == true
    assert LinkedData::Models::RestBackupMapping.all.count == 0

  end

  # Create and delete an interportal mapping
  def delete_interportal_mappings
    # For this test to work the test.rb config file has to include:
    # config.interportal_hash   = {"ncbo" => {"api" => "http://data.bioontology.org", "ui" => "http://bioportal.bioontology.org", "apikey" => "..."}}

    classes = ["http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Knowledge_Extraction",
               "http://neurolog.unice.fr/ontoneurolog/v3.0/dolce-particular.owl#event"
    ]
    mapping = { classes: classes,
                "subject_source_id": 'http://bioontology.org/ontologies/BiomedicalResourceOntology.owl',
                "object_source_id": 'http://data.bioontology.org/ontologies/OntoVIP',
                comment: "testing external mappings",
                name: 'test',
                relation: ["http://www.w3.org/2004/02/skos/core#exactMatch", "http://purl.org/linguistics/gold/translation"],
                creator: "tim"
    }

    post "/mappings", MultiJson.dump(mapping), "CONTENT_TYPE" => "application/json"
    assert last_response.status == 201, "Error creating the interportal mapping: #{last_response.body}"

    # to check if the interportal mapping we wanted have been created
    mapping_created = false

    LinkedData::Models::RestBackupMapping.all.each do |m|
      m_id = CGI.escape(m.id.to_s)
      get "/mappings/#{m_id}"
      assert last_response.status == 200
      mapping = MultiJson.load(last_response.body)
      assert mapping["classes"].length == 2
      mapping["classes"].each do |cls|
        if cls["@id"].to_s == "http://neurolog.unice.fr/ontoneurolog/v3.0/dolce-particular.owl#event"
          mapping_created = true
        end
      end

      assert mapping["process"] != nil
      delete "/mappings/#{m_id}"
      assert last_response.status == 204
      get "/mappings/#{m_id}"
      assert last_response.status == 404
    end
    assert mapping_created == true
    assert LinkedData::Models::RestBackupMapping.all.count == 0

  end

end

