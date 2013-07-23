require_relative '../test_case_helpers'

class TestHTTPCacheHelper < TestCaseHelpers

  def self.before_suite
    raise Exception, "Redis is unavailable, caching will not function" if LinkedData::HTTPCache::REDIS.ping.nil?
    self.new("before_suite").delete_ontologies_and_submissions
    ontologies = self.new("before_suite")._ontologies
    @@ontology = ontologies.shift
    @@ontology_alt = ontologies.shift
    @@ontology.bring_remaining

    @@note_user = "test_note_user"
    _delete_user
    @@user = LinkedData::Models::User.new(
      username: @@note_user,
      email: "note_user@example.org",
      password: "note_user_pass"
    )
    @@user.save

    @@note = LinkedData::Models::Note.new({
      creator: @@user,
      subject: "Test subject",
      body: "Test body for note",
      relatedOntology: [@@ontology]
    })
    @@note.save

    @@note_alt = LinkedData::Models::Note.new({
      creator: @@user,
      subject: "Test subject alt",
      body: "Test body for note alt",
      relatedOntology: [@@ontology_alt]
    })
    @@note_alt.save

    @orig_enable_cache = LinkedData.settings.enable_http_cache
    LinkedData.settings.enable_http_cache = true
  end

  def self.after_suite
    _delete_user
    LinkedData.settings.enable_http_cache = @orig_enable_cache
    self.new("after_suite").delete_ontologies_and_submissions
    LinkedData::HTTPCache.invalidate_all
  end

  def self._delete_user
    u = LinkedData::Models::User.find(@@note_user).first
    u.delete unless u.nil?
  end

  def _ontologies
    results = create_ontologies_and_submissions(ont_count: 2, submission_count: 1, process_submission: false)
    return results[2]
  end

  def test_cached_collection
    get '/ontologies'
    assert last_response.status == 200
    token = last_response.headers["Last-Modified"]
    get '/ontologies', {}, {"HTTP_IF_MODIFIED_SINCE" => token}
    assert last_response.status == 304
    sleep(1)
    @@ontology.name = "Test new name"
    @@ontology.save
    get '/ontologies'
    assert last_response.status == 200
  end

  def test_cached_single
    get '/ontologies/' + @@ontology.acronym
    assert last_response.status == 200
    token = last_response.headers["Last-Modified"]
    get '/ontologies/' + @@ontology.acronym, {}, {"HTTP_IF_MODIFIED_SINCE" => token}
    assert last_response.status == 304
    sleep(1)
    @@ontology.name = "Test new name"
    @@ontology.save
    get '/ontologies/' + @@ontology.acronym
    assert last_response.status == 200
  end

  def test_cached_segment
    get "/ontologies/#{@@ontology.acronym}/notes"
    token = last_response.headers["Last-Modified"]
    assert last_response.status == 200
    get "/ontologies/#{@@ontology.acronym}/notes", {}, {"HTTP_IF_MODIFIED_SINCE" => token}
    assert last_response.status == 304
    get "/ontologies/#{@@ontology_alt.acronym}/notes"
    token_alt = last_response.headers["Last-Modified"]
    assert last_response.status == 200
    get "/ontologies/#{@@ontology_alt.acronym}/notes", {}, {"HTTP_IF_MODIFIED_SINCE" => token_alt}
    assert last_response.status == 304
    sleep(1)
    @@note.subject = "New subject"
    @@note.save
    get "/ontologies/#{@@ontology.acronym}/notes", {}, {"HTTP_IF_MODIFIED_SINCE" => token}
    assert last_response.status == 200
    get "/ontologies/#{@@ontology_alt.acronym}/notes", {}, {"HTTP_IF_MODIFIED_SINCE" => token_alt}
    assert last_response.status == 304
  end
end