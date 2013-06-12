# This is the base class for controllers in the application.
# Code in the before or after blocks will run on every request
class ApplicationController
  include Sinatra::Delegator
  extend Sinatra::Delegator

  # Run before route
  before {
    if LinkedData.settings.enable_http_cache
      cache = LinkedData::HTTPCache.new(env: env)
      token = cache.validate(@response.headers)
      last_modified token unless token.nil?
    end
  }

  # Run after route
  after {
    if LinkedData.settings.enable_http_cache
      cache = LinkedData::HTTPCache.new(env: env, strategy: :last_modified)
      cache.invalidate
    end
  }

end