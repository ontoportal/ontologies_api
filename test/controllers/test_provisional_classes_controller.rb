require_relative '../test_case'

class TestProvisionalClassesController < TestCase
  def self.before_suite
    self.new("before_suite").delete_ontologies_and_submissions
    @@ontology, cls = self.new("before_suite")._ontology_and_class

    @@test_username = "test_provisional_user"
    _delete_user
    @@test_user = LinkedData::Models::User.new(
        username: @@test_username,
        email: "provisional_classes_user@example.org",
        password: "test_user_password"
    )
    @@test_user.save

    # Create a test provisional class
    @@test_pc = {label: "Really Nasty Melanoma", synonym: ["Nasty Melanoma", "Worst Melanoma"], definition: ["Melanoma of the nastiest kind known to men"], creator: @@test_user.id.to_s}

    @@pcs = []
    3.times do |i|
      pc = ProvisionalClass.new({
          creator: @@test_user,
          label: "Test Prov Class #{i}",
          synonym: ["Test synonym for Prov Class #{i}"],
          definition: ["Test definition for Prov Class #{i}"]
      })
      pc.save
    end
  end

  def self.after_suite
    self.new("after_suite").delete_ontologies_and_submissions
    pcs = ProvisionalClass.where(creator: @@test_user.id.to_s)
    pcs.each {|pc| pc.delete}
    _delete_user
  end

  def _ontology_and_class
    count, acronyms, ontologies = create_ontologies_and_submissions(ont_count: 1, submission_count: 1, process_submission: true)
    ontology = ontologies.first
    cls = LinkedData::Models::Class.where.include(:prefLabel).in(ontology.latest_submission).read_only.page(1, 1).first
    return ontology, cls
  end

  def self._delete_user
    u = LinkedData::Models::User.find(@@test_username).first
    u.delete unless u.nil?
  end

  def test_all_provisional_classes
    get '/provisional_classes'
    assert last_response.ok?
    pcs = MultiJson.load(last_response.body)
    assert pcs.length >= 3
  end

  def test_single_provisional_class
    get '/provisional_classes'
    pcs = MultiJson.load(last_response.body)
    pc = pcs.first
    get pc['@id']
    assert last_response.ok?
    retrieved_pc = MultiJson.load(last_response.body)
    assert_equal pc["@id"], retrieved_pc["@id"]
  end

  def test_provisional_class_lifecycle
    pc = {
        creator: @@test_user.id.to_s,
        label: "A Newest Form of Cancer",
        synonym: ["New Cancer", "2013 Cancer"],
        definition: ["A new form of cancer has just been discovered."]
    }
    post "/provisional_classes", MultiJson.dump(pc), "CONTENT_TYPE" => "application/json"
    assert last_response.status == 201

    new_pc = MultiJson.load(last_response.body)
    get new_pc["@id"]
    assert last_response.ok?

    pc_changes = {label: "A Form of Cancer No Longer New", permanentId: "http://purl.obolibrary.org/obo/MI_0914"}
    patch new_pc["@id"], MultiJson.dump(pc_changes), "CONTENT_TYPE" => "application/json"

    assert last_response.status == 204
    get new_pc["@id"]
    patched_pc = MultiJson.load(last_response.body)
    assert_equal patched_pc["label"], pc_changes[:label]

    delete new_pc["@id"]
    assert last_response.status == 204
  end
end