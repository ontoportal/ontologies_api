require_relative '../test_case'

class TestSlicesController < TestCase

  def self.before_suite
    ont_count, ont_acronyms, @@onts = LinkedData::SampleData::Ontology.create_ontologies_and_submissions(ont_count: 1, submission_count: 0)

    @@slice_acronyms = ["tst-a", "tst-b"].sort
    _create_slice(@@slice_acronyms[0], "Test Slice A", @@onts)
    _create_slice(@@slice_acronyms[1], "Test Slice B", @@onts)

    @@user = User.new({
                        username: "test-slice",
                        email: "test-slice@example.org",
                        password: "12345"
                      }).save
    @@new_slice_data = { acronym: 'tst-c', name: "Test Slice C", ontologies: ont_acronyms}
    @@old_security_setting = LinkedData.settings.enable_security
  end

  def self.after_suite
    LinkedData::Models::Slice.all.each(&:delete)
    @@user.delete
    reset_security(@@old_security_setting)
  end

  def setup
    self.class.reset_security(@@old_security_setting)
    self.class.reset_to_not_admin(@@user)
    LinkedData::Models::Slice.find(@@new_slice_data[:acronym]).first&.delete
  end

  def test_all_slices
    get "/slices"
    assert last_response.ok?
    slices = MultiJson.load(last_response.body)
    assert_equal @@slice_acronyms, slices.map { |s| s["acronym"] }.sort
  end

  def test_create_slices
    self.class.enable_security

    post "/slices?apikey=#{@@user.apikey}", MultiJson.dump(@@new_slice_data), "CONTENT_TYPE" => "application/json"
    assert_equal 403, last_response.status

    self.class.make_admin(@@user)

    post "/slices?apikey=#{@@user.apikey}", MultiJson.dump(@@new_slice_data), "CONTENT_TYPE" => "application/json"

    assert 201, last_response.status
  end

  def test_delete_slices
    self.class.enable_security
    LinkedData.settings.enable_security = @@old_security_setting
    self.class._create_slice(@@new_slice_data[:acronym],  @@new_slice_data[:name], @@onts)


    delete "/slices/#{@@new_slice_data[:acronym]}?apikey=#{@@user.apikey}"
    assert_equal 403, last_response.status

    self.class.make_admin(@@user)

    delete "/slices/#{@@new_slice_data[:acronym]}?apikey=#{@@user.apikey}"
    assert 201, last_response.status
  end

  private

  def self._create_slice(acronym, name, ontologies)
    slice = LinkedData::Models::Slice.new({
                                            acronym: acronym,
                                            name: "Test #{name}",
                                            ontologies: ontologies
                                          })
    slice.save
  end

end