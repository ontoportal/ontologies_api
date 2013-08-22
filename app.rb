# sinatra-base
require 'sinatra'

# sinatra-contrib
require 'sinatra/respond_with'
require 'sinatra/namespace'
require 'sinatra/advanced_routes'
require 'sinatra/multi_route'

# Other gem dependencies
require 'oj'
require 'multi_json'
require 'ontologies_linked_data'
require 'ncbo_annotator'
require 'ncbo_cron'

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

# mini-profiler sets the etag header to nil, so don't use when caching is enabled
if [:development].include?(settings.environment) && !LinkedData.settings.enable_http_cache
  begin
    require 'rack-mini-profiler'
    Rack::MiniProfiler.config.storage = Rack::MiniProfiler::FileStore
    Rack::MiniProfiler.config.position = 'right'
    c = ::Rack::MiniProfiler.config
    c.pre_authorize_cb = lambda { |env|
      true
    }
    tmp = File.expand_path("../tmp/miniprofiler", __FILE__)
    FileUtils.mkdir_p(tmp) unless File.exists?(tmp)
    c.storage_options = {path: tmp}
    use Rack::MiniProfiler
    puts ">> rack-mini-profiler is enabled"
  rescue LoadError
    # profiler isn't there
  end
end

# Use middleware (ORDER IS IMPORTANT)
if Goo.queries_debug?
  use Goo::Debug
end
use Rack::Accept
use Rack::PostBodyToParams
use LinkedData::Security::Authorization
use LinkedData::Security::AccessDenied

if LinkedData.settings.enable_http_cache
  require 'rack/cache'
  use Rack::Cache,
    :verbose     => true,
    :metastore   => 'file:./cache/rack/meta',
    :entitystore => 'file:./cache/rack/body'
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
