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
    "additionalProperties":false,
    "properties":{
      "creator":{ "type":"string", "required": true },
      "created":{ "type":"string", "format":"datetime", "required": true },
      "body":{ "type":"string", "required": true },
      "ontologyReviewed":{ "type":"string", "required": true },
      "usabilityRating":{ "type":"number" },
      "coverageRating":{ "type":"number" },
      "qualityRating":{ "type":"number" },
      "formalityRating":{ "type":"number" },
      "correctnessRating":{ "type":"number" },
      "documentationRating":{ "type":"number" },
    }
  }
  END_JSON_SCHEMA_STR

  def test_all_reviews
    get '/reviews'
    _response_status(200, last_response)
    assert_equal '[]', last_response.body
  end

  def test_single_review
    # TODO: Decide what unique key to use for review identification!
    #review = 'test_review'
    #get "/reviews/#{review}"
    #_response_status(200, last_response)
    #assert_equal '', last_response.body
  end

  def test_create_new_review
  end

  def test_update_replace_review
  end

  def test_update_patch_review
  end

  def test_delete_review
  end


  def _response_status(status, response)
    if DEBUG_MESSAGES
      assert_equal(status, response.status, response.body)
    else
      assert_equal(status, response.status)
    end
  end

  # Issues DELETE for a review acronym, tests for a 204 response.
  # @param [String] acronym review acronym
  def _review_delete(acronym)
    delete "/reviews/#{acronym}"
    _response_status(204, last_response)
  end

  # Issues GET for a review acronym, tests for a 200 response, with optional response validation.
  # @param [String] acronym review acronym
  # @param [boolean] validate_data verify response body json content
  def _review_get_success(acronym, validate_data=false)
    get "/reviews/#{acronym}"
    _response_status(200, last_response)
    if validate_data
      # Assume we have JSON data in the response body.
      p = JSON.parse(last_response.body)
      assert_instance_of(Hash, p)
      assert_equal(@p.acronym, p['acronym'], p.to_s)
      validate_json(last_response.body, JSON_SCHEMA_STR)
    end
  end

  # Issues GET for a review acronym, tests for a 404 response.
  # @param [String] acronym review acronym
  def _review_get_failure(acronym)
    get "/reviews/#{acronym}"
    _response_status(404, last_response)
  end
end
