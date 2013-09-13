module Rack
  class SlowRequests
    SLOW_QUERY = 2

    def initialize(app = nil, options = {})
      @app = app
      @log_path = options[:log_path] || File.expand_path("../../", __FILE__)
    end

    def call(env)
      start = Time.now
      data = @app.call(env)
      finish = Time.now
      if finish - start > SLOW_QUERY
        # Fire off a thread so we don't slow down the request
        Thread.new do
          open(@log_path, "a") do |f|
            f.puts "#{finish - start} #{env["REQUEST_METHOD"].to_s.upcase} #{env["REQUEST_URI"].to_s}"
          end
        end
      end
      data
    end
  end
end