require 'cube'

##
# This enables collection of request statistics for anaylsis via cube.
# A cube server is required. See http://square.github.io/cube/ for more info.
module Rack
  class CubeReporter

    def initialize(app = nil, options = {})
      host = options[:cube_host] || "localhost"
      port = options[:cube_port] || 1180
      @app = app
      @cube = ::Cube::Client.new(host, port)
    end

    def call(env)
      start = Time.now
      data = @app.call(env)
      finish = Time.now
      cache_hit = data[1]["X-Rack-Cache"] && data[1]["X-Rack-Cache"].eql?("fresh")
      @cube.send "ontologies_api_request", DateTime.now, duration_ms: ((finish - start)*1000).ceil, path: env["REQUEST_PATH"], cache_hit: cache_hit
      data
    end

  end
end