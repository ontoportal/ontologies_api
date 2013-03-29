# sinatra-base
require 'sinatra'

# sinatra-contrib
require 'sinatra/respond_with'
require 'sinatra/namespace'
require 'sinatra/advanced_routes'
require 'sinatra/multi_route'

# Other gem dependencies
require 'multi_json'
require 'oj'
require 'ontologies_linked_data'

# Require middleware
require 'rack/accept'
require 'rack/post-body-to-params'

# Logging setup
require_relative "config/logging"

# Setup root and static public directory
set :root, File.dirname(__FILE__)
use Rack::Static,
  :urls => ["/static"],
  :root => "public"

# Setup the environment
environment = settings.environment.nil? ? :development : settings.environment
require_relative "config/environments/#{environment}.rb"

# Development-specific options
if [:development, :console].include?(settings.environment)
  require 'pry' # Debug by placing 'binding.pry' where you want the interactive console to start
  # Show exceptions
  set :raise_errors, true
  set :dump_errors, false
  set :show_exceptions, false
end

# Use middleware (ORDER IS IMPORTANT)
use Rack::Accept
use Rack::PostBodyToParams
use LinkedData::Security::Authorization

if [:development].include?(settings.environment)
  begin
    require 'rack/perftools_profiler'
    use Rack::PerftoolsProfiler, :default_printer => :pdf, :mode => :cputime, :frequency => 1000
  rescue LoadError
    # perftools isn't there
  end
end

# Initialize the app
require_relative 'init'

# Enter console mode
if settings.environment == :console
  require 'rack/test'
  include Rack::Test::Methods; def app() Sinatra::Application end
  Pry.start binding, :quiet => true
  exit
end
