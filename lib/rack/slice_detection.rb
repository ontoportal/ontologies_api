module Rack
  class SliceDetection

    def initialize(app = nil, options = {})
      @app = app
    end

    def call(env)
      if env['HTTP_HOST']
        # remove the port if there is one
        domain = env['HTTP_HOST'].gsub(/:\d+$/, '')

        # store the first part of the domain, IE `slice.data.bioontology.org` becomes `slice`
        env['ncbo.slice'] = domain.split(".").first

        # override with header if used
        env['ncbo.slice'] = env["HTTP_NCBO_SLICE"] if env["HTTP_NCBO_SLICE"]

        # turn "brendan.app.com" to ".app.com"
        # and turn "app.com" to ".app.com"
        if domain.match(/([^.]+\.[^.]+)$/)
          domain = '.' + $1
        end

        env['rack.session.options'] ||= {}
        env['rack.session.options'] = env['rack.session.options'][:domain] = domain
      end

      @app.call(env)
    end
  end
end