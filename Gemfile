source 'https://rubygems.org'

gem 'activesupport', '~> 3.0'
# see https://github.com/ncbo/ontologies_api/issues/69
gem 'bigdecimal', '1.4.2'
gem 'google-api-client', '~> 0.10'
gem 'json-schema', '~> 2.0'
gem 'multi_json', '~> 1.0'
gem 'oj', '~> 2.0'
gem 'parseconfig'
gem 'rack'
gem 'rake', '~> 10.0'
gem 'sinatra', '~> 1.0'
gem 'sinatra-advanced-routes'
gem 'sinatra-contrib', '~> 1.0'

# Rack middleware
gem 'ffi'
gem 'rack-accept', '~> 0.4'
gem 'rack-attack', '~> 5.4.2', require: 'rack/attack'
gem 'rack-cache', '~> 1.0'
gem 'rack-cors', require: 'rack/cors'
gem 'rack-post-body-to-params', github: 'palexander/rack-post-body-to-params', branch: 'multipart_support' # github dependency can be removed when https://github.com/niko/rack-post-body-to-params/pull/6 is merged and released
gem 'rack-timeout'
gem 'redis-rack-cache', '~> 1.0'

# Data access (caching)
gem 'redis', '~> 3.3.3'
gem 'redis-activesupport'

# Monitoring
gem 'cube-ruby', require: 'cube'

# HTTP server
gem 'rainbows'
gem 'unicorn'
gem 'unicorn-worker-killer'

# Templating
gem 'haml'
gem 'redcarpet'

# NCBO gems (can be from a local dev path or from rubygems/git)
gem 'goo', github: 'ncbo/goo', branch: 'staging'
gem 'sparql-client', github: 'ncbo/sparql-client', branch: 'staging'
gem 'ontologies_linked_data', github: 'ncbo/ontologies_linked_data', branch: 'staging'
gem 'ncbo_annotator', github: 'ncbo/ncbo_annotator', branch: 'staging'
gem 'ncbo_cron', github: 'ncbo/ncbo_cron', branch: 'staging'
gem 'ncbo_ontology_recommender', github: 'ncbo/ncbo_ontology_recommender', branch: 'staging'

# NCBO gems (unversioned)
gem 'ncbo_resolver', github: 'ncbo/ncbo_resolver'
gem 'ncbo_resource_index', github: 'ncbo/resource_index'

group :production, :staging do
  gem 'newrelic_rpm'
end

group :development do
  gem 'capistrano', '~> 3', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-locally', require: false
  gem 'capistrano-rbenv', require: false
  gem 'pry'
  gem 'shotgun', github: 'palexander/shotgun', branch: 'ncbo'
end

group :profiling do
  gem 'rack-mini-profiler'
end

group :test do
  gem 'minitest', '~> 4.0'
  gem 'minitest-stub_any_instance'
  gem 'rack-test'
  gem 'simplecov', require: false
end
