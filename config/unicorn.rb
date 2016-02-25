application  = 'ontologies_api'
app_path = "/srv/ncbo/#{application}"
working_directory "#{app_path}/current/"

worker_processes 8
timeout 180 
preload_app true
user "ncbobp", "ncbobp"

stderr_path "log/unicorn.stderr.log"
#stdout_path "log/unicorn.stdout.log"
pid "/var/run/unicorn/unicorn.pid"

# Listen on both fast-failing unix data socket (for nginx) & a backloggable TCP connection
listen "/tmp/unicorn.sock", :backlog => 1024
listen 8088, :backlog => 256

# Make sure unicorn is using current gems after rolling restarts
before_exec do |server|
   ENV['BUNDLE_GEMFILE'] = "#{app_path}/current/Gemfile"
end

before_fork do |server, worker|
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!
 
  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.
 
  old_pid = "#{server.config[:pid]}.oldbin"
 
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end
 
after_fork do |server, worker|
  # Unicorn master loads the app then forks off workers - because of the way
  # Unix forking works, we need to make sure we aren't using any of the parent's
  # sockets, e.g. db connection
 
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
  # Redis and Memcached would go here but their connections are established
  # on demand, so the master never opens a socket
end
