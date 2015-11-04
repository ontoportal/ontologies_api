require_relative '../test_case'

class TestExternalMappingsController < TestCase

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
    NcboCron::Models::QueryWarmer.new(Logger.new(TestLogFile.new)).run
  end

  def test_mappings_controllers_in_order
    LinkedData::Models::RestBackupMapping.all.each do |m|
      LinkedData::Mappings.delete_rest_mapping(m.id)
    end
    create_external_mappings
    delete_external_mappings
    delete_interportal_mappings

  end


  def create_external_mappings

    classes = { "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Knowledge_Extraction"=> "BRO-TEST-MAP-0",
                "http://www.movieontology.org/2009/10/01/movieontology.owl#Love"=> "ext:http://www.movieontology.org/2010/01/movieontology.owl"
    }

    mapping = { classes: classes,
                comment: "testing external mappings",
                relation: ["http://www.w3.org/2004/02/skos/core#exactMatch", "http://purl.org/linguistics/gold/translation"],
                creator: "http://vm-bioportal-vincent:8080/users/admin"
    }

    post "/mappings/",
         MultiJson.dump(mapping),
         "CONTENT_TYPE" => "application/json"
    assert last_response.status == 201
    response = MultiJson.load(last_response.body)
    assert response["process"]["comment"] == "testing external mappings"
    assert response["process"]["creator"]["users/admin"]
    assert response["process"]["relation"] == ["http://www.w3.org/2004/02/skos/core#exactMatch", "http://purl.org/linguistics/gold/translation"]
    assert response["process"]["date"] != nil
  end


  def delete_external_mappings
    classes = { "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Knowledge_Extraction"=> "BRO-TEST-MAP-0",
                "http://www.movieontology.org/2009/10/01/movieontology.owl#Love"=> "ext:http://www.movieontology.org/2010/01/movieontology.owl"
    }
    mapping = { classes: classes,
                comment: "testing external mappings",
                relation: ["http://www.w3.org/2004/02/skos/core#exactMatch", "http://purl.org/linguistics/gold/translation"],
                creator: "http://vm-bioportal-vincent:8080/users/admin"
    }

    post "/mappings",
         MultiJson.dump(mapping),
         "CONTENT_TYPE" => "application/json"
    assert last_response.status == 201

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



  def delete_interportal_mappings
    # For this test to work the test.rb config file has to include:
    # config.interportal_hash   = {"ncbo" => {"api" => "http://data.bioontology.org", "ui" => "http://bioportal.bioontology.org"}}

    classes = { "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Knowledge_Extraction"=> "BRO-TEST-MAP-0",
                "http://neurolog.unice.fr/ontoneurolog/v3.0/dolce-particular.owl#event"=> "ncbo:OntoVIP"
    }
    mapping = { classes: classes,
                comment: "testing external mappings",
                relation: ["http://www.w3.org/2004/02/skos/core#exactMatch", "http://purl.org/linguistics/gold/translation"],
                creator: "http://vm-bioportal-vincent:8080/users/admin"
    }

    post "/mappings",
         MultiJson.dump(mapping),
         "CONTENT_TYPE" => "application/json"
    assert last_response.status == 201

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

