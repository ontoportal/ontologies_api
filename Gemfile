source 'https://rubygems.org'

gem 'activesupport', '~> 3.0'
# see https://github.com/ncbo/ontologies_api/issues/69
gem 'bigdecimal', '1.4.2'
gem 'faraday', '~> 1.9'
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
gem 'rack-post-body-to-params', git: 'https://github.com/palexander/rack-post-body-to-params.git', branch: "multipart_support" # github dependency can be removed when https://github.com/niko/rack-post-body-to-params/pull/6 is merged and released
gem 'rack-timeout'
gem 'redis-rack-cache', '~> 1.0'

# Data access (caching)
gem 'redis'
gem 'redis-activesupport'

# Monitoring
gem 'cube-ruby', require: 'cube'
gem 'newrelic_rpm'

# HTTP server
gem 'rainbows'
gem 'unicorn'
gem 'unicorn-worker-killer'

# Templating
gem 'haml'
gem 'redcarpet'

# NCBO gems (can be from a local dev path or from rubygems/git)
gem 'goo', git: 'https://github.com/ontoportal-lirmm/goo.git', branch: 'master'
gem 'ncbo_annotator', git: 'https://github.com/ontoportal-lirmm/ncbo_annotator.git', branch: 'master'
gem 'ncbo_cron', git: 'https://github.com/ontoportal-lirmm/ncbo_cron.git', branch: 'master'
gem 'ncbo_ontology_recommender', git: 'https://github.com/ncbo/ncbo_ontology_recommender.git', branch: 'master'
gem 'sparql-client', git: 'https://github.com/ncbo/sparql-client.git', branch: 'master'
gem 'ontologies_linked_data', git: 'https://github.com/ontoportal-lirmm/ontologies_linked_data.git', branch: 'master'

# NCBO gems (unversioned)
gem 'ncbo_resolver', git: 'https://github.com/ncbo/ncbo_resolver.git'
gem 'ncbo_resource_index', git: 'https://github.com/ncbo/resource_index.git'

group :development do
  gem 'capistrano', '~> 3', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-locally', require: false
  gem 'capistrano-rbenv', require: false
  gem 'pry'
  gem 'shotgun', git: 'https://github.com/palexander/shotgun.git', branch: 'ncbo'
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
