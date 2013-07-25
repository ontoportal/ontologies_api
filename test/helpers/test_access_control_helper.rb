require_relative '../test_case_helpers'

class TestAccessControlHelper < TestCaseHelpers

  def self.before_suite
    @@old_security_setting = LinkedData.settings.enable_security
    LinkedData.settings.enable_security = true

    self.new("before_suite").delete_ontologies_and_submissions

    @@usernames = ["user1", "user2", "user3", "admin"]
    _delete_users
    @@usernames.each do |username|
      user = LinkedData::Models::User.new(
        username: username,
        email: "#{username}@example.org",
        password: "note_user_pass"
      )
      user.save
      user.bring_remaining
      self.class_variable_set(:"@@#{username}", user)
    end

    @@admin.role = [LinkedData::Models::Users::Role.find(LinkedData::Models::Users::Role::ADMIN).first]
    @@admin.save

    onts = LinkedData::SampleData::Ontology.create_ontologies_and_submissions[2]

    @@restricted_ont = onts.shift
    @@restricted_ont.bring_remaining
    @@restricted_ont.viewingRestriction = "private"
    @@restricted_ont.acl = [@@user2, @@user3]
    @@restricted_ont.administeredBy = [@@user1]
    @@restricted_ont.save
    @@restricted_user = @@restricted_ont.administeredBy.first
    @@restricted_user.bring_remaining

    @@ont = onts.shift
    @@ont.bring_remaining
    @@user = @@ont.administeredBy.first
    @@user.bring_remaining
  end

  def self.after_suite
    LinkedData.settings.enable_security = @@old_security_setting
    _delete_users
    self.new("after_suite").delete_ontologies_and_submissions
    @@note.delete if class_variable_defined?("@@note")
  end

  def self._delete_users
    @@usernames.each {|u| user = LinkedData::Models::User.find(u).first; user.delete unless user.nil?}
  end

  def test_filtered_list
    get "/ontologies", apikey: @@user.apikey
    onts = MultiJson.load(last_response.body)
    assert onts.length == 4
    assert onts.any? {|o| o["@id"] == @@ont.id.to_s}
    refute onts.any? {|o| o["@id"] == @@restricted_ont.id.to_s}
  end

  def test_direct_access
    get "/ontologies/#{@@restricted_ont.acronym}", apikey: @@user.apikey
    assert last_response.status == 403
  end

  def test_based_on_access
    get "/ontologies/#{@@restricted_ont.acronym}/submissions", apikey: @@user.apikey
    assert last_response.status == 403
  end
end