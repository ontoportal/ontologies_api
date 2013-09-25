require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs = []
  t.test_files = FileList['test/**/test*.rb'].select { |x| !x["resource_index"]}
end

Rake::TestTask.new do |t|
  t.libs = []
  t.name = "test:controllers"
  t.test_files = FileList['test/controllers/test*.rb']
end

Rake::TestTask.new do |t|
  t.libs = []
  t.name = "test:models"
  t.test_files = FileList['test/models/test*.rb']
end

Rake::TestTask.new do |t|
  t.libs = []
  t.name = "test:helpers"
  t.test_files = FileList['test/helpers/test*.rb']
end

Rake::TestTask.new do |t|
  t.libs = []
  t.name = "test:lib"
  t.test_files = FileList['test/lib/test*.rb']
end

desc "Run test coverage analysis"
task :coverage do
  puts "Code coverage reports will be visible in the /coverage folder"
  ENV["COVERAGE"] = "true"
  Rake::Task["test"].invoke
end

namespace :unicorn do
  namespace :start do
    desc "Unicorn start (production settings)"
    task :production do
      print "Starting unicorn...\n"
      `bundle exec unicorn -p 80 -c config/unicorn.rb -D -E production`
    end

    desc "Unicorn start (development settings)"
    task :development do
      print "Starting unicorn...\n"
      `bundle exec unicorn -p 9393 -c config/unicorn.rb`
    end
  end

  desc "Unicorn stop"
  task :stop do
    `pkill -QUIT -f 'unicorn master'`
    if $?.exitstatus == 1
      puts "Unicorn not running"
    elsif $?.exitstatus == 0
      print "Killing unicorn..."
      pids = `pgrep -f 'unicorn master'`
      while !pids.empty?
        print "."
        pids = `pgrep -f 'unicorn master'`
      end
      print "\n"
    end
  end
end

namespace :cache do
  namespace :clear do
    desc "Clear HTTP cache (production redis and Rack::Cache)"
    task :production do
      require 'ontologies_linked_data'
      require 'ncbo_annotator'
      require_relative "config/config"
      require_relative 'config/environments/production.rb'
      LinkedData::HTTPCache.invalidate_all
      `rm -rf cache/`
    end

    desc "Clear HTTP cache (development redis and Rack::Cache)"
    task :development do
      require 'ontologies_linked_data'
      require 'ncbo_annotator'
      require_relative "config/config"
      require_relative 'config/environments/development.rb'
      LinkedData::HTTPCache.invalidate_all
      `rm -rf cache/`
    end
  end
end

namespace :deploy do
  desc "Deploy production"
  task :production do
    puts 'Deploying ontologies_api'
    puts 'Doing pull'
    `git pull`
    puts 'Updating bundle'
    `bundle update`
    puts 'Restarting unicorn'
    `sudo env PATH=$PATH rake unicorn:stop`
    `sudo env PATH=$PATH rake unicorn:start:production`
    puts 'Clearing cache'
    `bundle exec rake cache:clear:production`
  end

  desc "Deploy production using rsync instead of git pull"
  task :production_rsync do
    puts 'Deploying ontologies_api'
    puts 'Doing rsync'
    `rsync -av  ncboprod-rest1:/srv/ncbo/ontologies_api/current/* /srv/ncbo/ontologies_api/current/`
    puts 'Updating bundle'
    `bundle update`
    puts 'Restarting unicorn'
    `sudo env PATH=$PATH rake unicorn:stop`
    `sudo env PATH=$PATH rake unicorn:start:production`
    puts 'Clearing cache'
    `bundle exec rake cache:clear:production`
  end
end
