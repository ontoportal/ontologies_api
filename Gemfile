source 'https://rubygems.org'

gem 'rack', github: 'palexander/rack', branch: 'patch-1' # can remove github dependency when this is merged: https://github.com/rack/rack/pull/621
gem 'sinatra', '~> 1.0'
gem 'sinatra-contrib', '~> 1.0'
gem 'sinatra-advanced-routes'
gem 'multi_json', '~> 1.0'
gem 'oj', '~> 2.0'
gem 'json-schema', '~> 2.0'
gem 'rake', '~> 10.0'
gem 'activesupport', '~> 3.0'

# Rack middleware
gem 'rack-accept', '~> 0.4'
gem 'rack-post-body-to-params', github: "palexander/rack-post-body-to-params", branch: "multipart_support" # github dependency can be removed when https://github.com/niko/rack-post-body-to-params/pull/6 is merged and released
gem 'rack-cache', '~> 1.0'
gem 'redis-rack-cache', '~> 1.0'
gem 'rack-timeout'

# Data access (caching)
gem 'redis', '~> 3.0'

# Testing
gem 'simplecov', :require => false, :group => :test
gem 'minitest', '~> 4.0'

# Monitoring
gem 'cube-ruby', require: 'cube'

# HTTP server
gem 'rainbows'

# Debugging
gem 'pry', :group => :development

# Profiling
gem 'rack-mini-profiler', :group => :profiling

# Code reloading
gem 'shotgun', :group => 'development', :git => 'https://github.com/palexander/shotgun.git', :branch => 'ncbo'

# Templating
gem 'haml'
gem 'redcarpet'

# NCBO gems (can be from a local dev path or from rubygems/git)
ncbo_branch = ENV["NCBO_BRANCH"] || `git rev-parse --abbrev-ref HEAD`.strip || "staging"
gem 'goo', github: 'ncbo/goo', branch: ncbo_branch
gem 'sparql-client', github: 'ncbo/sparql-client', branch: ncbo_branch
gem 'ontologies_linked_data', github: 'ncbo/ontologies_linked_data', branch: ncbo_branch
gem 'ncbo_annotator', github: 'ncbo/ncbo_annotator', branch: ncbo_branch
gem 'ncbo_cron', github: 'ncbo/ncbo_cron', branch: ncbo_branch

# Not versioned
gem 'ncbo_resolver', github: "ncbo/ncbo_resolver"
gem 'ncbo_resource_index_client', github: 'ncbo/resource_index_ruby_client'
