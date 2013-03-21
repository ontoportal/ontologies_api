require_relative '../test_case'

class TestSearchController < TestCase

  def setup
  end

  def teardown
  end

  def test_search
    get '/search?q=melanoma&page=1&pagesize=2'
    assert last_response.ok?
  end

end