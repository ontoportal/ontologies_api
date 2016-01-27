source 'https://rubygems.org'

gem 'rack'
gem 'sinatra', '~> 1.0'
gem 'sinatra-contrib', '~> 1.0'
gem 'sinatra-advanced-routes'
gem 'multi_json', '~> 1.0'
gem 'oj', '~> 2.0'
gem 'json-schema', '~> 2.0'
gem 'rake', '~> 10.0'
gem 'activesupport', '~> 3.0'
gem 'google-api-client', '<0.9'

# Rack middleware
gem 'rack-accept', '~> 0.4'
gem 'rack-post-body-to-params', github: "palexander/rack-post-body-to-params", branch: "multipart_support" # github dependency can be removed when https://github.com/niko/rack-post-body-to-params/pull/6 is merged and released
gem 'rack-cache', '~> 1.0'
gem 'redis-rack-cache', '~> 1.0'
gem 'rack-timeout'
gem 'rack-cors', :require => 'rack/cors'
gem 'rack-attack', :require => 'rack/attack'

# Data access (caching)
gem 'redis', '~> 3.0'

# Pegging this to a particular commit because 4.2.1 is broken.
# After redis-activesupport gets a version bump you can remove the 'git' and 'ref' param
#gem 'redis-activesupport', github: 'redis-store/redis-activesupport', ref: 'c107458a2a6b5e7019c7f9410a8eb5307f921e61'
gem 'redis-activesupport'

# Testing
gem 'simplecov', :require => false, :group => :test
gem 'minitest', '~> 4.0'
gem 'minitest-stub_any_instance'

# Monitoring
gem 'cube-ruby', require: 'cube'
gem 'newrelic_rpm'

# HTTP server
gem 'unicorn'
gem 'rainbows'
gem 'unicorn-worker-killer'

# Debugging
gem 'pry', :group => :development

# Profiling
gem 'rack-mini-profiler', :group => :profiling

# Code reloading
gem 'shotgun', :group => 'development', :git => 'https://github.com/palexander/shotgun.git', :branch => 'ncbo'

# Templating
gem 'haml'
gem 'redcarpet'

# Deployments
gem 'capistrano', '~> 3.4.0', :require => false, :group => :development
gem 'capistrano-bundler', '~> 1.1.1', :require => false, :group => :development
gem 'capistrano-rbenv', '~> 2.0.2', :require => false, :group => :development

# NCBO gems (can be from a local dev path or from rubygems/git)
gem 'goo', github: 'ncbo/goo', branch: 'master'
gem 'sparql-client', github: 'ncbo/sparql-client', branch: 'master'
gem 'ontologies_linked_data', github: 'ncbo/ontologies_linked_data', branch: 'master'
gem 'ncbo_annotator', github: 'ncbo/ncbo_annotator', branch: 'master'
gem 'ncbo_cron', github: 'ncbo/ncbo_cron', branch: 'master'
gem 'ncbo_ontology_recommender', github: 'ncbo/ncbo_ontology_recommender', branch: 'master'

# Not versioned
gem 'ncbo_resolver', github: 'ncbo/ncbo_resolver'
gem 'ncbo_resource_index', github: 'ncbo/resource_index'
