require_relative '../test_case'
require "date"

class TestHTTPCache < TestCase

  def setup
    refute LinkedData::HTTPCache::REDIS.ping.nil?, "Redis is unavailable, caching will not function"
    @orig_enable_cache = LinkedData.settings.enable_http_cache
    LinkedData.settings.enable_http_cache = true
  end

  def teardown
    LinkedData.settings.enable_http_cache = @orig_enable_cache
  end

  def test_last_modified_response
    get "/"
    token = last_response.headers["Last-Modified"]
    last_modified = DateTime.parse(token)
    assert DateTime.now > last_modified
    assert last_modified > (DateTime.now - 35)
  end

  def test_cache_validation
    get "/"
    token = last_response.headers["Last-Modified"]
    get "/", {}, {"HTTP_IF_MODIFIED_SINCE" => token}
    assert last_response.status == 304
    get "/"
    assert last_response.status == 200
  end

  def test_cache_disabled
    LinkedData.settings.enable_http_cache = false
    get "/"
    assert last_response.headers["Last-Modified"].nil?
  end

  def test_cache_invalidate_all_entries
    LinkedData.settings.enable_http_cache = true
    get "/"
    get "/ontologies"
    get "/groups"
    assert last_response.ok?
    n = LinkedData::HTTPCache.size
    assert n >= 3
    inv_n = LinkedData::HTTPCache.invalidate_all_entries
    assert_equal n, inv_n
    n = LinkedData::HTTPCache.size
    assert_equal 0, n
  end

end
