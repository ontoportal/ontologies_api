require_relative '../test_case'

class TestClsesController < TestCase
  def test_all_clses
    ontology = 'ncit'
    get "/ontologies/#{ontology}/classes"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_single_cls
    num_onts_created, created_ont_acronyms = create_ontologies_and_submissions(ont_count: 1, submission_count: 1, process_submission: true)
    clss_ids = [ 'http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Molecular_Interaction',
            "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Electron_Microscope" ]

    clss_ids.each do |cls_id|
      escaped_cls= CGI.escape(cls_id)
      ont = Ontology.find(created_ont_acronyms.first)
      ont.load unless ont.loaded?
      get "/ontologies/#{ont.acronym}/classes/#{escaped_cls}"
      assert last_response.ok?
      cls = JSON.parse(last_response.body)
      assert(!cls["prefLabel"].nil?)
      assert_instance_of(String, cls["prefLabel"])
      assert_instance_of(Array, cls["synonyms"])
      assert(cls["id"] == cls_id)
      if cls["prefLabel"].include? "Electron"
        assert_equal(1, cls["synonyms"].length)
        assert_instance_of(String, cls["synonyms"][0])
      else
        assert_equal(0, cls["synonyms"].length)
      end
    end
  end

  def test_roots_for_cls
    num_onts_created, created_ont_acronyms = create_ontologies_and_submissions(ont_count: 1, submission_count: 1, process_submission: true)
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
