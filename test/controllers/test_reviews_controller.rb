require_relative '../test_case'

class TestReviewsController < TestCase

  DEBUG_MESSAGES = false

  # JSON Schema
  # This could be in the Review model, see
  # https://github.com/ncbo/ontologies_linked_data/issues/22
  # json-schema for description and validation of REST json responses.
  # http://tools.ietf.org/id/draft-zyp-json-schema-03.html
  # http://tools.ietf.org/html/draft-zyp-json-schema-03
  JSON_SCHEMA_STR = <<-END_JSON_SCHEMA_STR
  {
    "type":"object",
    "title":"Review",
    "description":"A BioPortal ontology review.",
    "additionalProperties":true,
    "properties":{
      "@id":{ "type":"string", "format":"uri", "required": true },
      "@type":{ "type":"string", "format":"uri", "required": true },
      "creator":{ "type":"string", "format":"uri", "required": true },
      "created":{ "type":"string", "format":"datetime", "required": true },
      "body":{ "type":"string", "required": true },
      "ontologyReviewed":{ "type":"string", "required": true },
      "usabilityRating":{ "type":"number" },
      "coverageRating":{ "type":"number" },
      "qualityRating":{ "type":"number" },
      "formalityRating":{ "type":"number" },
      "correctnessRating":{ "type":"number" },
      "documentationRating":{ "type":"number" }
    }
  }
  END_JSON_SCHEMA_STR

  # Clear the triple store models
  def teardown
    super
    delete_goo_models(LinkedData::Models::Review.all)
    delete_goo_models(LinkedData::Models::Ontology.all)
    delete_goo_models(LinkedData::Models::User.all)
    @review_params = nil
    @user = nil
    @ont = nil
  end

  def setup
    super
    @user = LinkedData::Models::User.new(username: "test_user", email: "test_user@example.org", password: "password")
    @user.save
    @ont = LinkedData::Models::Ontology.new(acronym: "TST", name: "TEST ONTOLOGY", administeredBy: @user)
    @ont.save
    @review_params = {
        :creator => @user.username.value,
        :created => DateTime.new,
        :body => "This is a test review.",
        :ontologyReviewed => @ont.acronym.value,
        :usabilityRating => 0,
        :coverageRating => 0,
        :qualityRating => 0,
        :formalityRating => 0,
        :correctnessRating => 0,
        :documentationRating => 0,
    }
    @review = LinkedData::Models::Review.new()
    @review.creator = @user
    @review.created = @review_params[:created]
    @review.body = @review_params[:body]
    @review.ontologyReviewed = @ont
    @review.usabilityRating = @review_params[:usabilityRating]
    @review.coverageRating = @review_params[:coverageRating]
    @review.qualityRating = @review_params[:qualityRating]
    @review.formalityRating = @review_params[:formalityRating]
    @review.correctnessRating = @review_params[:correctnessRating]
    @review.documentationRating = @review_params[:documentationRating]
    assert @review.valid?
    @review.save
  end

  def test_reviews
    # The setup creates a single review for ontology 'TST' by creator 'test_user'
    get '/reviews'
    _response_status(200, last_response)
    reviews = MultiJson.load(last_response.body)
    assert_instance_of(Array, reviews)
    assert_equal(1, reviews.length)
    r = reviews[0]
    assert_instance_of(Hash, r)
    assert_equal(@user.resource_id, r['creator'])
    assert_equal(@ont.resource_id, r['ontologyReviewed'])
    validate_json(last_response.body, JSON_SCHEMA_STR, true)
  end

  def test_review_get
    _reviews_get_success(@ont, @user, true)
  end

  def test_review_create_success
    # Ensure it doesn't exist first (undo the setup creation)
    _reviews_delete(@ont.acronym, @user.username)
    put "/ontologies/#{@ont.acronym}/reviews/#{@user.username}", MultiJson.dump(@review_params), "CONTENT_TYPE" => "application/json"
    _response_status(201, last_response)
    _reviews_get_success(@ont, @user, true)
  end

  def test_review_create_conflict
    # Fail PUT for any review that already exists.
    put "/ontologies/#{@ont.acronym}/reviews/#{@user.username}", MultiJson.dump(@review_params), "CONTENT_TYPE" => "application/json"
    _response_status(409, last_response)
    # The existing project should remain valid
    _reviews_get_success(@ont, @user, true)
  end

  def test_review_create_failure
    # Ensure the review doesn't exist.
    _reviews_delete(@ont.acronym, @user.username)
    # Fail PUT for any review with required missing data.
    username = 'user_name_does_not_exist'
    @review_params[:creator] = username
    put "/ontologies/#{@ont.acronym}/reviews/#{username}", MultiJson.dump(@review_params), "CONTENT_TYPE" => "application/json"
    _response_status(422, last_response)
    _reviews_get_failure(@ont.acronym, username)
  end

  def test_review_update_success
    # Use patch for existing reviews (it is created in the setup)
    @review_params[:qualityRating] = @review_params[:qualityRating] + 1
    patch "/ontologies/#{@ont.acronym}/reviews/#{@user.username}", MultiJson.dump(@review_params), "CONTENT_TYPE" => "application/json"
    _response_status(204, last_response)
    _reviews_get_success(@ont, @user, true)
  end

  def test_delete_review
    _reviews_delete(@ont.acronym, @user.username)
    _reviews_get_failure(@ont.acronym, @user.username)
  end

  def _response_status(status, response)
    if DEBUG_MESSAGES
      assert_equal(status, response.status, response.body)
    else
      assert_equal(status, response.status)
    end
  end

  # Issues DELETE for a review of an ontology by a user, tests for a 204 response.
  # @param [String] acronym review ontology acronym
  # @param [String] username review username
  def _reviews_delete(acronym, username)
    delete "/ontologies/#{acronym}/reviews/#{username}"
    _response_status(204, last_response)
  end


  # Issues GET for a review acronym, tests for a 200 response, with optional response validation.
  # @param [String] acronym review ontology acronym
  # @param [String] username review username
  # @param [boolean] validate_data verify response body json content
  def _reviews_get_success(ont, user, validate_data=false)
    get "/ontologies/#{ont.acronym}/reviews/#{user.username}"
    _response_status(200, last_response)
    if validate_data
      # Assume we have JSON data in the response body.
      reviews = MultiJson.load(last_response.body)
      assert_instance_of(Array, reviews)
      r = reviews[0]
      assert_instance_of(Hash, r)
      assert_equal(user.resource_id, r['creator'], r.to_s)
      assert_equal(ont.resource_id, r['ontologyReviewed'])
      validate_json(last_response.body, JSON_SCHEMA_STR, true)
    end
  end

  # Issues GET for an ontology review by a user, tests for a 404 response.
  # @param [String] acronym review ontology acronym
  # @param [String] username review username
  def _reviews_get_failure(acronym, username)
    get "/ontologies/#{acronym}/reviews/#{username}"
    _response_status(404, last_response)
  end
end
