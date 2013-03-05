require_relative '../test_case'

class TestClsesController < TestCase

  def setup_only_once
    return create_ontologies_and_submissions(
     ont_count: 1, submission_count: 3, process_submission: true, random_submission_count: false)
  end

  def test_first_default_page
    num_onts_created, created_ont_acronyms = setup_only_once
    ont = Ontology.find(created_ont_acronyms.first)
    ont.load unless ont.loaded?

    submission_ids = [nil, 2,3]
    submission_ids.each do |submission_id|
        call = "/ontologies/#{ont.acronym}/classes"
        call << "?ontology_submission_id=#{submission_id}" if submission_id
        get call
        assert last_response.ok?
        clss = JSON.parse(last_response.body)
        #TODO when fixed https://github.com/ncbo/ontologies_linked_data/issues/32
        #more testing needs to be done here
        assert last_response.ok?
        assert clss["classes"].length == 50 #default size
    end
  end

  def test_all_class_pages
    num_onts_created, created_ont_acronyms = setup_only_once

    ont = Ontology.find(created_ont_acronyms.first)
    ont.load unless ont.loaded?

    page_response = nil
    count_terms = 0
    begin
      call = "/ontologies/#{ont.acronym}/classes"
      if page_response
        call <<  "?page=#{page_response['next']}&size=#{page_response['size']}"
      end
      get call
      assert last_response.ok?
      page_response = JSON.parse(last_response.body)
      #TODO when fixed https://github.com/ncbo/ontologies_linked_data/issues/32
      #more testing needs to be done here
      assert last_response.ok?
      count_terms = count_terms + page_response["classes"].length
    end while page_response["next"]
    assert count_terms == Integer(page_response["count"])
  end

  def test_single_cls
    num_onts_created, created_ont_acronyms = setup_only_once

    clss_ids = [ 'http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Molecular_Interaction',
            "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Electron_Microscope" ]

    ont = Ontology.find(created_ont_acronyms.first)
    ont.load unless ont.loaded?

    submission_ids = [nil, 2,3]
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
        assert_instance_of(Array, cls["synonym"])
        assert(cls["@id"] == cls_id)

        if submission_id == nil or submission_id == 3
          assert(cls["prefLabel"]["In version 3.2"])
          assert(cls["definition"][0]["In version 3.2"])
        else
          assert(!cls["prefLabel"]["In version 3.2"])
          assert(!cls["definition"][0]["In version 3.2"])
        end

        if cls["prefLabel"].include? "Electron"
          assert_equal(1, cls["synonym"].length)
          assert_instance_of(String, cls["synonym"][0])
        else
          assert_equal(0, cls["synonym"].length)
        end
      end
    end
  end

  def test_roots_for_cls

    num_onts_created, created_ont_acronyms = setup_only_once

    ont = Ontology.find(created_ont_acronyms.first)
    ont.load unless ont.loaded?
    get "/ontologies/#{ont.acronym}/classes/roots"
    assert last_response.ok?
    roots = JSON.parse(last_response.body)
    assert_equal 9, roots.length
    roots.each do |r|
      assert_instance_of String, r["prefLabel"]
      assert_instance_of String, r["@id"]
      #By definition roots have no parents
      escaped_root_id= CGI.escape(r["@id"])
      get "/ontologies/#{ont.acronym}/classes/#{escaped_root_id}/parents"
      last_response.ok?
      parents = JSON.parse(last_response.body)
      assert parents.length == 0
    end
  end

  def test_classes_for_not_parsed_ontology

    num_onts_created, created_ont_acronyms = setup_only_once

    ont = Ontology.find(created_ont_acronyms.first)
    ont.load unless ont.loaded?
    #first submission was not parsed
    get "/ontologies/#{ont.acronym}/classes/roots?ontology_submission_id=1"

    assert_equal 400, last_response.status
    assert last_response.body["has not been parsed"]
  end

  def test_tree_for_cls

    num_onts_created, created_ont_acronyms = setup_only_once

    ont = Ontology.find(created_ont_acronyms.first)
    ont.load unless ont.loaded?
    clss_ids = [ 'http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Molecular_Interaction',
            "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Electron_Microscope" ]
    clss_ids.each do |cls_id|
      escaped_cls= CGI.escape(cls_id)
      call = "/ontologies/#{ont.acronym}/classes/#{escaped_cls}/tree"
      get call
      assert last_response.ok?
    end
  end

  def test_ancestors_for_cls

    num_onts_created, created_ont_acronyms = setup_only_once

    ont = Ontology.find(created_ont_acronyms.first)
    ont.load unless ont.loaded?
    ancestors_data = {}
    ancestors_data['http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Molecular_Interaction'] =[
      "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Data_Resource",
      "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Information_Resource",
      "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Molecular_and_Cellular_Data",
      "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Resource",
      ]
    ancestors_data['http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Electron_Microscope'] =[
      "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Instrument",
      "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Material_Resource",
      "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Microscope",
      "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Resource",
      ]

    clss_ids = [ 'http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Molecular_Interaction',
            "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Electron_Microscope" ]
    clss_ids.each do |cls_id|
      escaped_cls= CGI.escape(cls_id)
      call = "/ontologies/#{ont.acronym}/classes/#{escaped_cls}/ancestors"
      get call
      assert last_response.ok?
      ancestors = JSON.parse(last_response.body)
      ancestors.map! { |a| a["@id"] }
      assert ancestors.sort == ancestors_data[cls_id].sort
    end
  end

  def test_descendants_for_cls
    num_onts_created, created_ont_acronyms = setup_only_once

    ont = Ontology.find(created_ont_acronyms.first)
    ont.load unless ont.loaded?

    descendants_data = {}
    descendants_data['http://bioontology.org/ontologies/ResearchArea.owl#Area_of_Research'] =[
      "http://bioontology.org/ontologies/ResearchArea.owl#Behavioral_Science",
 "http://bioontology.org/ontologies/ResearchArea.owl#Bioinformatics",
 "http://bioontology.org/ontologies/ResearchArea.owl#Biostatistics",
 "http://bioontology.org/ontologies/ResearchArea.owl#Clinical_Studies",
 "http://bioontology.org/ontologies/ResearchArea.owl#Computational_Biology",
 "http://bioontology.org/ontologies/ResearchArea.owl#Epidemiology",
 "http://bioontology.org/ontologies/ResearchArea.owl#Genomics",
 "http://bioontology.org/ontologies/ResearchArea.owl#Metabolomics",
 "http://bioontology.org/ontologies/ResearchArea.owl#Nursing",
 "http://bioontology.org/ontologies/ResearchArea.owl#Outcomes_Research",
 "http://bioontology.org/ontologies/ResearchArea.owl#Pathology",
 "http://bioontology.org/ontologies/ResearchArea.owl#Pediatrics",
 "http://bioontology.org/ontologies/ResearchArea.owl#Pharmacokinetics_Pharmacodynamics",
 "http://bioontology.org/ontologies/ResearchArea.owl#Physiology",
 "http://bioontology.org/ontologies/ResearchArea.owl#Preclinical",
 "http://bioontology.org/ontologies/ResearchArea.owl#Proteomics",
 "http://bioontology.org/ontologies/ResearchArea.owl#Psychometrics",
 "http://bioontology.org/ontologies/ResearchArea.owl#Research_IT",
 "http://bioontology.org/ontologies/ResearchArea.owl#Toxicology"]

    descendants_data['http://bioontology.org/ontologies/Activity.owl#Activity'] =
      ["http://bioontology.org/ontologies/Activity.owl#Biospecimen_Management",
 "http://bioontology.org/ontologies/Activity.owl#Community_Engagement",
 "http://bioontology.org/ontologies/Activity.owl#Gene_Therapy",
 "http://bioontology.org/ontologies/Activity.owl#Health_Services",
 "http://bioontology.org/ontologies/Activity.owl#IRB",
 "http://bioontology.org/ontologies/Activity.owl#Medical_Device_Development",
 "http://bioontology.org/ontologies/Activity.owl#Regulatory_Compliance",
 "http://bioontology.org/ontologies/Activity.owl#Research_Funding",
 "http://bioontology.org/ontologies/Activity.owl#Research_Lab_Management",
 "http://bioontology.org/ontologies/Activity.owl#Resource_Inventory",
 "http://bioontology.org/ontologies/Activity.owl#Small_Molecule",
 "http://bioontology.org/ontologies/Activity.owl#Social_Networking",
 "http://bioontology.org/ontologies/Activity.owl#Software_Development",
 "http://bioontology.org/ontologies/Activity.owl#Surgical_Procedure",
 "http://bioontology.org/ontologies/Activity.owl#Therapeutics",
 "http://bioontology.org/ontologies/Activity.owl#Training"]

    clss_ids = [ 'http://bioontology.org/ontologies/Activity.owl#Activity',
            "http://bioontology.org/ontologies/ResearchArea.owl#Area_of_Research" ]
    clss_ids.each do |cls_id|
      escaped_cls= CGI.escape(cls_id)
      call = "/ontologies/#{ont.acronym}/classes/#{escaped_cls}/descendants"
      get call
      assert last_response.ok?
      descendants = JSON.parse(last_response.body)
      assert descendants["page"] == 1
      descendants = descendants["classes"]
      descendants.map! { |a| a["@id"] }
      assert descendants.sort == descendants_data[cls_id].sort
    end

    #Smaller pages
    clss_ids.each do |cls_id|
      escaped_cls= CGI.escape(cls_id)
      descendants = []
      page_response = nil
      begin
        call = "/ontologies/#{ont.acronym}/classes/#{escaped_cls}/descendants?size=7"
        if page_response
          call << "&page=#{page_response["next"]}"
        end
        get call
        assert last_response.ok?
        page_response = JSON.parse(last_response.body)
        descendants.concat page_response["classes"]
      end while page_response["next"]
      descendants.map! { |a| a["@id"] }
      assert descendants.sort == descendants_data[cls_id].sort
    end
  end

  def test_parents_for_cls_round_trip
    num_onts_created, created_ont_acronyms = setup_only_once

    clss_ids = [ 'http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Molecular_Interaction',
            "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Electron_Microscope" ]

    parent_ids = ["http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Molecular_and_Cellular_Data",
    "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Microscope"]

    ont = Ontology.find(created_ont_acronyms.first)
    ont.load unless ont.loaded?

    clss_ids.each_index do |i|
      cls_id = clss_ids[i]
      escaped_cls= CGI.escape(cls_id)
      call = "/ontologies/#{ont.acronym}/classes/#{escaped_cls}/parents"
      get call
      assert last_response.ok?
      parents = JSON.parse(last_response.body)
      assert parents[0]["@id"] == parent_ids[i]

      #the children of every parent must contain himself.
      parents.each do |p|
        escaped_p_id= CGI.escape(p["@id"])
        call = "/ontologies/#{ont.acronym}/classes/#{escaped_p_id}/children"
        get call
        last_response.ok?
        children = JSON.parse(last_response.body)
        children = children["classes"]
        children.map! { |c| c["@id"] }
        assert children.length > 0 and children.include? cls_id
      end
    end
  end

  def test_children_for_cls_round_trip
    num_onts_created, created_ont_acronyms = setup_only_once

    clss_ids = [ 'http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Molecular_and_Cellular_Data',
            "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Microscope" ]

    children_arrays = [
      [
        "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Gene_Expression",
        "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Molecular_Interaction",
        "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Phenotypic_Measurement",
        "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Protein_Expression"
      ] , [
        "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Electron_Microscope",
        "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Light_Microscope"
      ] ]

    ont = Ontology.find(created_ont_acronyms.first)
    ont.load unless ont.loaded?

    clss_ids.each_index do |i|
      cls_id = clss_ids[i]
      escaped_cls= CGI.escape(cls_id)
      call = "/ontologies/#{ont.acronym}/classes/#{escaped_cls}/children"
      get call
      assert last_response.ok?
      children = JSON.parse(last_response.body)["classes"]
      #TODO eventually this should test for id and not resource_id
      children.map! { |c| c["@id"] }
      assert children.sort == children_arrays[i].sort

      #the parent of every children must contain himself.
      children.each do |c|
        escaped_c_id= CGI.escape(c)
        call = "/ontologies/#{ont.acronym}/classes/#{escaped_c_id}/parents"
        get call
        last_response.ok?
        parents = JSON.parse(last_response.body)
        parents.map! { |p| p["@id"] }
        assert parents.length > 0 and parents.include? cls_id
      end
    end
  end

end
