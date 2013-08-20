require_relative '../test_case'

class TestAnnotatorController < TestCase

  def self.before_suite
    @@redis = Redis.new(:host => LinkedData.settings.redis_host, :port => LinkedData.settings.redis_port)
    db_size = @@redis.dbsize
    if db_size > 2000
      puts "   This test cannot be run. You are probably pointing to the wrong redis backend. "
      return
    end

    LinkedData::SampleData::Ontology.delete_ontologies_and_submissions
    @@ontologies = LinkedData::SampleData::Ontology.sample_owl_ontologies
    annotator = Annotator::Models::NcboAnnotator.new
    annotator.create_term_cache_from_ontologies(@@ontologies)
    mapping_test_set
  end
  
  def self.after_suite
    LinkedData::SampleData::Ontology.delete_ontologies_and_submissions
  end

  def test_annotate
    text = <<eos
Ginsenosides chemistry, biosynthesis, analysis, and potential health effects in software concept or data." "Ginsenosides are a special group of triterpenoid saponins that can be classified into two groups by the skeleton of their aglycones, namely dammarane- and oleanane-type. Ginsenosides are found nearly exclusively in Panax species (ginseng) and up to now more than 150 naturally occurring ginsenosides have been isolated from roots, leaves/stems, fruits, and/or flower heads of ginseng. The same concept indicates Ginsenosides have been the target of a lot of research as they are believed to be the main active principles behind the claims of ginsengs efficacy. The potential health effects of ginsenosides that are discussed in this chapter include anticarcinogenic, immunomodulatory, anti-inflammatory, antiallergic, antiatherosclerotic, antihypertensive, and antidiabetic effects as well as antistress activity and effects on the central nervous system. Ginsensoides can be metabolized in the stomach (acid hydrolysis) and in the gastrointestinal tract (bacterial hydrolysis) or transformed to other ginsenosides by drying and steaming of ginseng to more bioavailable and bioactive ginsenosides. The metabolization and transformation of intact ginsenosides, which seems to play an important role for their potential health effects, are discussed. Qualitative and quantitative analytical techniques for the analysis of ginsenosides are important in relation to quality control of ginseng products and plant material and for the determination of the effects of processing of plant material as well as for the determination of the metabolism and bioavailability of ginsenosides. Analytical techniques for the analysis of ginsenosides that are described in this chapter are thin-layer chromatography (TLC), high-performance liquid chromatography (HPLC) combined with various detectors, gas chromatography (GC), colorimetry, enzyme immunoassays (EIA), capillary electrophoresis (CE), nuclear magnetic resonance (NMR) spectroscopy, and spectrophotometric methods.
eos
    params = {text: text}
    get "/annotator", params
    assert last_response.ok?
    annotations = MultiJson.load(last_response.body)
  end

  def test_annotate_hierarchy
    text = "Aggregate Human Data chromosomal mutation Aggregate Human Data chromosomal deletion Aggregate Human Data Resource Federal Funding Resource receptor antagonists chromosomal mutation"

    params = {text: text, max_level: 5}
    get "/annotator", params
    assert last_response.ok?
    annotations = MultiJson.load(last_response.body)
    
    assert annotations.length == 9
    
    assert annotations[0]["annotatedClass"]["@id"] == "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Aggregate_Human_Data"
    hhh = annotations[0]["hierarchy"].sort {|x| x["distance"]}.map { |x| x["annotatedClass"]["@id"] }
    assert hhh == ["http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Resource",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Information_Resource",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Clinical_Care_Data",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Data_Resource"]
    
    assert annotations[1]["annotatedClass"]["@id"] == "http://purl.obolibrary.org/obo/MCBCC_0000288#ChromosomalMutation"
    hhh = annotations[1]["hierarchy"].sort {|x| x["distance"]}.map { |x| x["annotatedClass"]["@id"] }
    assert hhh == ["http://purl.obolibrary.org/obo/MCBCC_0000287#GeneticVariation"]

    assert annotations[2]["annotatedClass"]["@id"] == "http://purl.obolibrary.org/obo/MCBCC_0000289#ChromosomalDeletion"
    hhh = annotations[2]["hierarchy"].sort {|x| x["distance"]}.map { |x| x["annotatedClass"]["@id"] }
    assert hhh == ["http://purl.obolibrary.org/obo/MCBCC_0000287#GeneticVariation",
            "http://purl.obolibrary.org/obo/MCBCC_0000288#ChromosomalMutation"]

    assert annotations[3]["annotatedClass"]["@id"] == "http://purl.obolibrary.org/obo/MCBCC_0000296#Deletion"
    hhh = annotations[3]["hierarchy"].sort {|x| x["distance"]}.map { |x| x["annotatedClass"]["@id"] }
    assert hhh == ["http://purl.obolibrary.org/obo/MCBCC_0000287#GeneticVariation", 
                   "http://purl.obolibrary.org/obo/MCBCC_0000295#GeneMutation" ] 
      
    assert annotations[4]["annotatedClass"]["@id"] == "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Data_Resource"
    hhh = annotations[4]["hierarchy"].sort {|x| x["distance"]}.map { |x| x["annotatedClass"]["@id"] }
    assert hhh == ["http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Resource",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Information_Resource"]


    assert annotations[5]["annotatedClass"]["@id"] == "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Resource"
    hhh = annotations[5]["hierarchy"].sort {|x| x["distance"]}.map { |x| x["annotatedClass"]["@id"] }
    assert hhh == []
      
    assert annotations[6]["annotatedClass"]["@id"] == "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Federal_Funding_Resource"
    hhh = annotations[6]["hierarchy"].sort {|x| x["distance"]}.map { |x| x["annotatedClass"]["@id"] }
    assert hhh == ["http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Resource",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Funding_Resource"]

    assert annotations[7]["annotatedClass"]["@id"] == "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Funding_Resource"
    hhh = annotations[7]["hierarchy"].sort {|x| x["distance"]}.map { |x| x["annotatedClass"]["@id"] }
    assert hhh == ["http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Resource"]

    assert annotations[8]["annotatedClass"]["@id"] == "http://purl.obolibrary.org/obo/MCBCC_0000275#ReceptorAntagonists"
    hhh = annotations[8]["hierarchy"].sort {|x| x["distance"]}.map { |x| x["annotatedClass"]["@id"] }
    assert hhh == ["http://purl.obolibrary.org/obo/MCBCC_0000256#ChemicalsAndDrugs"]
  end

  def test_annotate_with_mappings
    text = "Aggregate Human Data chromosomal mutation Aggregate Human Data chromosomal deletion Aggregate Human Data Resource Federal Funding Resource receptor antagonists chromosomal mutation"

    params = {text: text,mappings: "all"}
    get "/annotator", params
    assert last_response.ok?
    annotations = MultiJson.load(last_response.body)

    step_in_here = 0
    annotations.each do |ann|
      if ann["annotatedClass"]["@id"] == 
          "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Aggregate_Human_Data"
        step_in_here += 1
        assert ann["mappings"].length == 1
        assert ann["mappings"].first["annotatedClass"]["@id"] == 
            "http://www.semanticweb.org/associatedmedicine/lavima/2011/10/Ontology1.owl#Article"
        assert ann["mappings"].first["annotatedClass"]["links"]["ontology"]["OntoMATEST-0"]
      elsif ann["annotatedClass"]["@id"] == 
          "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Data_Resource"
        step_in_here += 1
        assert ann["mappings"].length == 2
        ann["mappings"].each do |map|
          if map["annotatedClass"]["@id"] =="http://www.semanticweb.org/associatedmedicine/lavima/2011/10/Ontology1.owl#Maux_de_rein"
            assert map["annotatedClass"]["links"]["ontology"]["OntoMATEST-0"]
          elsif map["annotatedClass"]["@id"] == "http://purl.obolibrary.org/obo/MCBCC_0000344#PapillaryInvasiveDuctalTumor"
            assert map["annotatedClass"]["links"]["ontology"]["MCCLTEST-0"]
          else
            assert 1==0
          end
        end
      else
        ann["mappings"].length == 0
      end
    end
    assert step_in_here == 2

  end

  def test_annotate_mappings_with_ontologies

    text = "Aggregate Human Data chromosomal mutation Aggregate Human Data chromosomal deletion Aggregate Human Data Resource Federal Funding Resource receptor antagonists chromosomal mutation"

    ontologies = "http://data.bioontology.org/ontologies/OntoMATEST-0," +
                 "http://data.bioontology.org/ontologies/BROTEST-0"
    params = {text: text,mappings: "all", ontologies: ontologies }
    get "/annotator", params
    assert last_response.ok?
    annotations = MultiJson.load(last_response.body)

    step_in_here = 0
    annotations.each do |ann|
      if ann["annotatedClass"]["@id"] == 
          "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Aggregate_Human_Data"
        step_in_here += 1
        assert ann["mappings"].length == 1
        assert ann["mappings"].first["annotatedClass"]["@id"] == 
            "http://www.semanticweb.org/associatedmedicine/lavima/2011/10/Ontology1.owl#Article"
        assert ann["mappings"].first["annotatedClass"]["links"]["ontology"]["OntoMATEST-0"]
      elsif ann["annotatedClass"]["@id"] == 
          "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Data_Resource"
        step_in_here += 1
        assert ann["mappings"].length == 1
        ann["mappings"].each do |map|
          if map["annotatedClass"]["@id"] =="http://www.semanticweb.org/associatedmedicine/lavima/2011/10/Ontology1.owl#Maux_de_rein"
            assert map["annotatedClass"]["links"]["ontology"]["OntoMATEST-0"]
          else
            assert 1==0
          end
        end
      else
        assert ann["annotatedClass"]["links"]["ontology"]["BROTEST-0"] || 
               ann["annotatedClass"]["links"]["ontology"]["OntoMATEST-0"]
        ann["mappings"].length == 0
      end
    end
    assert step_in_here == 2
  end


  #TODO: this method is duplicated in NCBO_ANNOTATOR
  def self.mapping_test_set
    terms_a = ["http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Resource",
               "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Aggregate_Human_Data",
               "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Data_Resource",
               "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Data_Resource"]
    onts_a = ["BROTEST-0","BROTEST-0","BROTEST-0","BROTEST-0"]
    terms_b = ["http://www.semanticweb.org/associatedmedicine/lavima/2011/10/Ontology1.owl#La_mastication_de_produit",
               "http://www.semanticweb.org/associatedmedicine/lavima/2011/10/Ontology1.owl#Article",
               "http://www.semanticweb.org/associatedmedicine/lavima/2011/10/Ontology1.owl#Maux_de_rein",
               "http://purl.obolibrary.org/obo/MCBCC_0000344#PapillaryInvasiveDuctalTumor"]
    onts_b = ["OntoMATEST-0","OntoMATEST-0","OntoMATEST-0", "MCCLTEST-0"]

    user_creator = LinkedData::Models::User.where.include(:username).page(1,100).first
    if user_creator.nil?
      u = LinkedData::Models::User.new(username: "tim", email: "tim@example.org", password: "password")
      u.save
      user_creator = LinkedData::Models::User.where.include(:username).page(1,100).first
    end
    process = LinkedData::Models::MappingProcess.new(:creator => user_creator, :name => "TEST Mapping Annotator")
    process.date = DateTime.now 
    process.relation = RDF::URI.new("http://bogus.relation.com/predicate")
    process.save

    4.times do |i|
      term_mappings = []
      term_mappings << LinkedData::Mappings.create_term_mapping([RDF::URI.new(terms_a[i])], onts_a[i])
      term_mappings << LinkedData::Mappings.create_term_mapping([RDF::URI.new(terms_b[i])], onts_b[i])
      mapping_id = LinkedData::Mappings.create_mapping(term_mappings)
      LinkedData::Mappings.connect_mapping_process(mapping_id, process)
    end
  end

end
