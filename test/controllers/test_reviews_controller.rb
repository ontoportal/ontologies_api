require_relative '../test_case'

class TestReviewsController < TestCase
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