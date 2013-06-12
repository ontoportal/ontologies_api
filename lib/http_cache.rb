require 'redis'
require 'time'
require 'securerandom'

module LinkedData
  class HTTPCache
    REDIS = Redis.new(host: LinkedData.settings.redis_host, port: LinkedData.settings.redis_port)
    @@redis_available = nil
    CACHE_INVALIDATION_VERBS = Set.new(["POST", "PUT", "PATCH", "DELETE"])
    CACHE_MAX_AGE = 2592000 # 2592000 == 30 days

    def initialize(options = {})
      @env = options[:env]
      raise ArgumentError, "Need to provide the rack env variable to use HTTPCache" if @env.nil?
      @strategy = options[:strategy] || :last_modified # Set to :etag to use etags by default
      @request = Rack::Request.new(@env)
      @validator_token = parse_validator_token
      @@redis_available ||= REDIS.ping.eql?("PONG") rescue false # Ping redis to make sure it's available
    end

    ##
    # Invalidate the cache for this request
    def invalidate(invalidate_list = true)
      return unless @@redis_available
      return unless CACHE_INVALIDATION_VERBS.include?(@request.env["REQUEST_METHOD"])
      key, field = redis_key_and_field
      REDIS.hdel(key, field)
      if invalidate_list
        key = key.split(":")
        field = key.pop || "top"
        REDIS.hdel(key.join(":"), field)
      end
    end

    ##
    # Validate existence of token and create if it doesn't exist
    # Add appropriate cache headers if headers are provided
    def validate(headers = nil)
      return unless @@redis_available
      return if CACHE_INVALIDATION_VERBS.include?(@request.env["REQUEST_METHOD"])
      cache_headers(headers) if headers
      cached? ? get_validator : generate_validator
    end

    ##
    # Set appropriate cache headers to tell rack-cache and other servers what should change
    # the cached response
    def cache_headers(headers)
      raise ArgumentError, "`headers` should be a hash of headers" unless headers.is_a?(Hash)
      headers["Vary"] = "User-Agent, Accept, Accept-Language, Accept-Encoding, Authorization"
      headers["Cache-Control"] = "public, max-age=#{CACHE_MAX_AGE}"
    end

    private

    ##
    # Examine the request header for an appropriate validator (provided by client)
    # Header location differs depending on strategy employed
    def parse_validator_token
      if @strategy == :etag
        return @request.env['HTTP_IF_NONE_MATCH'] && @request.env['HTTP_IF_NONE_MATCH'].gsub(/^"(.*)"$/, '\1')
      elsif @strategy == :last_modified
        return @request.env['HTTP_IF_MODIFIED_SINCE'] && @request.env['HTTP_IF_MODIFIED_SINCE'].gsub(/^"(.*)"$/, '\1')
      end
    end

    ##
    # Returns a new validator token, depending on the strategy
    def generate_validator
      if @strategy == :etag
        return generate_etag
      elsif @strategy == :last_modified
        return generate_last_modified
      end
    end

    ##
    # Check to see if the current request's validator is the same as the stored one for this URL
    def content_changed?
      return true if @validator_token.nil? || @validator_token.empty?
      validator = get_validator
      return !@validator_token.eql?(validator)
    end

    ##
    # Check to see if the stored validator for this URL exists, indicating the page is cached
    def cached?
      !get_validator.nil?
    end

    ##
    # Get the existing validator (return nil if it doesn't exist)
    def get_validator
      key, field = redis_key_and_field
      REDIS.hmget(key, field).first
    end

    ##
    # Generate and store an etag for this path
    def generate_etag
      key, field = redis_key_and_field
      etag = SecureRandom.base64(16)
      REDIS.hmset(key, field, etag)
      etag
    end

    ##
    # Generate a last modified header date for the current request
    def generate_last_modified
      key, field = redis_key_and_field
      last_modified = Time.now.httpdate
      REDIS.hmset(key, field, last_modified)
      last_modified
    end

    ##
    # Using the current path, create a redis key and hash field name
    def redis_key_and_field
      @path ||= @request.path.split("/").select {|e| !e.empty?}
      path = @path.dup
      @field ||= path.pop || "top"
      separator = path.empty? ? "" : ":"
      @key ||= "http_cache#{separator}#{path.join(":")}"
      return @key, @field
    end

    ##
    # invalidate all http cache entries
    def self.invalidate_all_entries
      entries = REDIS.keys(pattern="http_cache*")
      entries_size = entries.length
      entries.each do |http_cache_key|
        REDIS.del("http_cache")
      end
      return entries_size
    end

    ##
    # get the size (number o entries) in the cache
    def self.size
      return REDIS.keys(pattern="http_cache*").length
    end

  end
end
