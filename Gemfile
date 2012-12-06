source 'https://rubygems.org'

gem 'sinatra'
gem 'sinatra-contrib'
gem 'json'
gem 'rake'
gem 'rack-accept'

# HTTP server
gem 'thin'

# Debugging
gem 'pry', :group => 'development'

# Code reloading
gem 'shotgun', :group => 'development', :git => 'https://github.com/palexander/shotgun.git', :branch => 'ncbo'

# NCBO gems (can be from a local dev path or from rubygems/git)
gemfile_local = File.expand_path("../Gemfile.local", __FILE__)
if File.exists?(gemfile_local)
  self.instance_eval(Bundler.read_file(gemfile_local))
else
  gem 'goo', :git => 'https://github.com/ncbo/goo.git'
  gem 'sparql_http', :git => 'https://github.com/ncbo/sparql_http.git'
  gem 'ontologies_linked_data', :git => 'https://github.com/ncbo/ontologies_linked_data.git'
end

