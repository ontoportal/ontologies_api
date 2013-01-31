require_relative '../test_case'

class TestClsesController < TestCase
  def test_all_clses
    ontology = 'ncit'
    get "/ontologies/#{ontology}/classes"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_single_cls
    num_onts_created, created_ont_acronyms = create_ontologies_and_submissions(ont_count: 1, submission_count: 2, process_submission: true)
    clss_ids = [ 'http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Molecular_Interaction',
            "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Electron_Microscope" ]

    ont = Ontology.find(created_ont_acronyms.first)
    ont.load unless ont.loaded?

    submission_ids = [nil, 1, 2]
    #last submission is nil
    submission_ids.each do |submission_id|
      clss_ids.each do |cls_id|
        escaped_cls= CGI.escape(cls_id)
        call = "/ontologies/#{ont.acronym}/classes/#{escaped_cls}"
        call << "?ontology_submission_id=#{submission_id}" if submission_id
        get call
        assert last_response.ok?
        cls = JSON.parse(last_response.body)
        assert(!cls["prefLabel"].nil?)
        assert_instance_of(String, cls["prefLabel"])
        assert_instance_of(Array, cls["synonyms"])
        assert(cls["id"] == cls_id)

        if submission_id == nil or submission_id == 2
          assert(cls["prefLabel"]["In version 3.2"])
          assert(cls["definitions"][0]["In version 3.2"])
        else
          assert(!cls["prefLabel"]["In version 3.2"])
          assert(!cls["definitions"][0]["In version 3.2"])
        end

        if cls["prefLabel"].include? "Electron"
          assert_equal(1, cls["synonyms"].length)
          assert_instance_of(String, cls["synonyms"][0])
        else
          assert_equal(0, cls["synonyms"].length)
        end
      end
    end
  end

  def test_roots_for_cls
    num_onts_created, created_ont_acronyms = create_ontologies_and_submissions(ont_count: 1, submission_count: 2, process_submission: true)
    ont = Ontology.find(created_ont_acronyms.first)
    ont.load unless ont.loaded?
    get "/ontologies/#{ont.acronym}/classes/roots"
    assert last_response.ok?
    roots = JSON.parse(last_response.body)
    assert_equal 12, roots.length
    roots.each do |r|
      assert_instance_of String, r["prefLabel"]
      assert_instance_of String, r["id"]
    end
  end

  def test_classes_for_not_parsed_ontology
    #In this test we do not process the submimission
    num_onts_created, created_ont_acronyms = create_ontologies_and_submissions(ont_count: 1, submission_count: 1)
    ont = Ontology.find(created_ont_acronyms.first)
    ont.load unless ont.loaded?
    get "/ontologies/#{ont.acronym}/classes/roots"
    assert_equal 400, last_response.status
    assert last_response.body["has not been parsed"]
  end

  def test_tree_for_cls
  end

  def test_ancestors_for_cls
  end

  def test_descendants_for_cls
  end

  def test_children_for_cls
  end

  def test_parents_for_cls
  end

end
