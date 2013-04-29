# Recursively require files from directories and their sub-directories
def require_dir(dir)
  Dir.glob("#{dir}/*.rb").each {|f| require_relative f }
  Dir.glob("#{dir}/*/").each {|d| require_dir(d.gsub(/\/+$/, '')) }
end

# Require controller base files
require_relative "controllers/application_controller"

# Require known directories
require_dir("lib")
require_dir("helpers")
require_dir("models")
require_dir("controllers")

##
# Look for routes without an optional trailing slash or existing trailing slash
# and add the optional trailing slash so both /ontologies/ and /ontologies works
def rewrite_routes_trailing_slash
  trailing_slash = Regexp.new(/.*\/\?\\z/)
  no_trailing_slash = Regexp.new(/(.*)\\z\//)
  Sinatra::Application.routes.each do |method, routes|
    routes.each do |r|
      route_regexp_str = r[0].inspect
      if trailing_slash.match(route_regexp_str)
        next
      else
        new_route = route_regexp_str.gsub(no_trailing_slash, "\\1\\/?\\z/")
        r[0] = eval(new_route)
      end
    end
  end
end
rewrite_routes_trailing_slash()