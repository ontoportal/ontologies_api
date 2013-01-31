require_relative '../test_case'

class TestReviewsController < TestCase

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

  def _project_json_schema
    JSON.parse(JSON_SCHEMA_STR)
  end

  def test_all_reviews
    get '/reviews'
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_single_review
    review = 'test_review'
    get "/reviews/#{review}"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_create_new_review
  end

  def test_update_replace_review
  end

  def test_update_patch_review
  end

  def test_delete_review
  end

end
