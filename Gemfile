source 'https://rubygems.org'

gem 'activesupport', '~> 3.2'
# see https://github.com/ncbo/ontologies_api/issues/69
gem 'bigdecimal', '1.4.2'
gem 'faraday', '~> 1.9'
gem 'json-schema', '~> 2.0'
gem 'multi_json', '~> 1.0'
gem 'oj', '~> 2.0'
gem 'parseconfig'
gem 'rack'
gem 'rake', '~> 10.0'
gem 'sinatra', '~> 1.0'
gem 'sinatra-advanced-routes'
gem 'sinatra-contrib', '~> 1.0'
gem 'request_store'
gem 'parallel'
gem 'json-ld'


# Rack middleware
gem 'ffi'
gem 'rack-accept', '~> 0.4'
gem 'rack-attack', '~> 6.6.1', require: 'rack/attack'
gem 'rack-cache', '~> 1.13.0'
gem 'rack-cors', require: 'rack/cors'
# GitHub dependency can be removed when https://github.com/niko/rack-post-body-to-params/pull/6 is merged and released
gem 'rack-post-body-to-params', github: 'palexander/rack-post-body-to-params', branch: 'multipart_support'
gem 'rack-timeout'
gem 'redis-rack-cache', '~> 2.0'

# Data access (caching)
gem 'redis'
gem 'redis-store', '~>1.10'

# Monitoring
gem 'cube-ruby', require: 'cube'
gem 'newrelic_rpm'

# HTTP server
gem 'unicorn'
gem 'unicorn-worker-killer'

# Templating
gem 'haml', '~> 5.2.2' # pin see https://github.com/ncbo/ontologies_api/pull/107
gem 'redcarpet'

# NCBO gems (can be from a local dev path or from rubygems/git)
gem 'ncbo_annotator', git: 'https://github.com/ontoportal-lirmm/ncbo_annotator.git', branch: 'development'
gem 'ncbo_cron', git: 'https://github.com/ontoportal-lirmm/ncbo_cron.git', branch: 'master'
gem 'ncbo_ontology_recommender', git: 'https://github.com/ncbo/ncbo_ontology_recommender.git', branch: 'master'
gem 'goo', github: 'ontoportal-lirmm/goo', branch: 'development'
gem 'sparql-client', github: 'ontoportal-lirmm/sparql-client', branch: 'development'
gem 'ontologies_linked_data', git: 'https://github.com/ontoportal-lirmm/ontologies_linked_data.git', branch: 'development'

group :development do
  # bcrypt_pbkdf and ed35519 is required for capistrano deployments when using ed25519 keys; see https://github.com/miloserdow/capistrano-deploy/issues/42
  gem 'bcrypt_pbkdf', '>= 1.0', '< 2.0', require: false
  gem 'capistrano', '~> 3', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-locally', require: false
  gem 'capistrano-rbenv', require: false
  gem 'ed25519', '>= 1.2', '< 2.0', require: false
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
  gem 'simplecov-cobertura' # for codecov.io
  gem 'webmock', '~> 3.19.1'
end