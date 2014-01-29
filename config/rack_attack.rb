puts "(API) >> Throttling enabled at #{LinkedData::OntologiesAPI.settings.req_per_second_per_ip} req/sec"

require 'rack/attack'
require 'redis-activesupport'
use Rack::Attack

attack_redis_host_port = "#{LinkedData::OntologiesAPI.settings.http_redis_host}:#{LinkedData::OntologiesAPI.settings.http_redis_port}"
attack_store = ActiveSupport::Cache::RedisStore.new(attack_redis_host_port)
Rack::Attack.cache.store = attack_store

Rack::Attack.whitelist('always allow') do |req|
  req.env["REMOTE_USER"] && (req.env["REMOTE_USER"].username == "ncbobioportal" || req.env["REMOTE_USER"].admin?)
end

Rack::Attack.throttle('req/ip', :limit => LinkedData::OntologiesAPI.settings.req_per_second_per_ip, :period => 1.second) do |req|
  req.ip
end

Rack::Attack.throttled_response = lambda do |env|
  data = env['rack.attack.match_data']
  body = "You have made #{data[:count]} requests in the last #{data[:period]} seconds. We limit API Keys to #{data[:limit]} requests every #{data[:period]} seconds"
  [429, {}, [body]]
end