source 'https://rubygems.org'

gem 'sinatra'
gem 'sinatra-contrib'
gem 'sinatra-advanced-routes'
gem 'multi_json'
gem 'oj'
gem 'json-schema', '= 2.0.0'
gem 'rake'
gem 'rack-accept'
gem 'rack-post-body-to-params'
gem 'simplecov', :require => false, :group => :test
gem 'minitest', '< 5.0'
gem 'rack-cache'
gem 'redis'

# HTTP server
gem 'unicorn'
gem 'thin'

# Debugging
gem 'pry', :group => :development

# Profiling
gem 'rack-mini-profiler', :group => :profiling

# Code reloading
gem 'shotgun', :group => 'development', :git => 'https://github.com/palexander/shotgun.git', :branch => 'ncbo'

# NCBO gems (can be from a local dev path or from rubygems/git)
gemfile_local = File.expand_path("../Gemfile.local", __FILE__)
if File.exists?(gemfile_local)
  self.instance_eval(Bundler.read_file(gemfile_local))
else
  gem 'sparql-client', :git => 'https://github.com/ncbo/sparql-client.git'
  gem 'goo', :git => 'https://github.com/ncbo/goo.git'
  gem 'ontologies_linked_data', :git => 'https://github.com/ncbo/ontologies_linked_data.git'
  gem 'ncbo_resource_index_client', :git => 'https://github.com/ncbo/resource_index_ruby_client.git'
  gem 'ncbo_annotator', :git => 'https://github.com/ncbo/ncbo_annotator.git'
end

# ontologies_api-specific gems
gem 'haml'
gem 'redcarpet'
gem 'activesupport', '< 4.0'
