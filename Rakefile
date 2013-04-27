require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs = []
  t.test_files = FileList['test/**/test*.rb']
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
      `unicorn -p 80 -c config/unicorn.rb -D -E production`
    end

    desc "Unicorn start (development settings)"
    task :development do
      `unicorn -p 9393 -c config/unicorn.rb -E production`
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
    end
  end
end  
