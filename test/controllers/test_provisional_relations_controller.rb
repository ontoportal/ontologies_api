require_relative '../test_case'

class TestProvisionalRelationsController < TestCase
  def self.before_suite
    self.new("before_suite").delete_ontologies_and_submissions
    @@ontology, @@cls = self.new("before_suite")._ontology_and_class

    @@test_username = "test_provisional_user"
    @@test_user = LinkedData::Models::User.new(
        username: @@test_username,
        email: "provisional_classes_user@example.org",
        password: "test_user_password"
    )
    @@test_user.save

    # Create a test provisional class
    @@test_pc = ProvisionalClass.new({
        creator: @@test_user,
        label: "Really Nasty Melanoma",
        synonym: ["Test synonym for Prov Class Nasty Melanoma", "Test syn for class Worst Melanoma"],
        definition: ["Test definition for Prov Class Worst and Nasty Melanoma"]
    })
    @@test_pc.save

    #Create a test provisional relation
    @@test_rel = LinkedData::Models::ProvisionalRelation.new({
        source: @@test_pc,
        relationType: RDF::IRI.new("http://www.w3.org/2004/02/skos/core#exactMatch"),
        targetClassId: @@cls.id,
        targetClassOntology: @@ontology
    })
    @@test_rel.save
  end

  def self.after_suite
    @@test_pc.delete
    @@test_user.delete
  end

  def _ontology_and_class
    count, acronyms, ontologies = create_ontologies_and_submissions(ont_count: 1, submission_count: 1, process_submission: true)
    ontology = ontologies.first
    sub = ontology.latest_submission(status: :rdf)
    cls = LinkedData::Models::Class.in(sub).include(:prefLabel).page(1, 1).first
    return ontology, cls
  end

  def test_all_provisional_relations
    get '/provisional_relations'
    assert last_response.ok?
    rels = MultiJson.load(last_response.body)
    assert_equal 1, rels.length
  end

end

