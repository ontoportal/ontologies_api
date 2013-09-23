module LinkedData::OntologiesAPI
  extend self
  attr_reader :settings

  @settings = OpenStruct.new
  @settings_run = false

  def config(&block)
    return if @settings_run
    @settings_run = true

    yield @settings if block_given?

    # Set defaults
    @settings.enable_monitoring     ||= false
    @settings.cube_host             ||= "localhost"
    @settings.cube_port             ||= 1180
    @settings.slow_request_log      ||= File.expand_path("../../logs/slow_requests.log", __FILE__)
    @settings.http_cache_redis_host ||= "localhost"
    @settings.http_cache_redis_port ||= 6379
    @settings.ontology_rank         ||= {}

    @settings.resolver_cache_redis_host ||= "localhost"
    @settings.resolver_cache_redis_port ||= 6379

    if @settings.enable_monitoring
      puts ">> Slow queries log enabled: #{@settings.slow_request_log}"
      puts ">> Using cube server #{@settings.cube_host}:#{@settings.cube_port}"
    end
  end

end
