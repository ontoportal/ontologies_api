require_relative '../test_case'
# recommender_v1 is deprecated as of 2024-10-27
# TODO: remove completely after 2025-10-27
class TestRecommenderV1Controller < TestCase
  def test_recommender_v1_deprecation
    params = {
       :text => 'recommender v1 is deprecated'
    }
    get "/recommender_v1", params
    assert_equal 410, last_response.status
  end
end
