set :author, "ontoportal-lirmm"
set :application, "ontologies_api"
set :repo_url, "https://github.com/#{fetch(:author)}/#{fetch(:application)}.git"

set :deploy_via, :remote_cache

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
set :deploy_to, "/srv/ontoportal/#{fetch(:application)}"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :error

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
set :linked_dirs, %w{log vendor/bundle tmp/pids tmp/sockets public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5
set :config_folder_path, "#{fetch(:application)}/#{fetch(:stage)}"

# If you want to restart using `touch tmp/restart.txt`, add this to your config/deploy.rb:

SSH_JUMPHOST = ENV.include?('SSH_JUMPHOST') ? ENV['SSH_JUMPHOST'] : 'jumpbox.hostname.com'
SSH_JUMPHOST_USER = ENV.include?('SSH_JUMPHOST_USER') ? ENV['SSH_JUMPHOST_USER'] : 'username'

JUMPBOX_PROXY = "#{SSH_JUMPHOST_USER}@#{SSH_JUMPHOST}"
set :ssh_options, {
  user: 'ontoportal',
  forward_agent: 'true',
  keys: %w(config/deploy_id_rsa),
  auth_methods: %w(publickey),
  # use ssh proxy if API servers are on a private network
  proxy: Net::SSH::Proxy::Command.new("ssh #{JUMPBOX_PROXY} -W %h:%p")
}

# private git repo for configuraiton
PRIVATE_CONFIG_REPO = ENV.include?('PRIVATE_CONFIG_REPO') ? ENV['PRIVATE_CONFIG_REPO'] : 'https://your_github_pat_token@github.com/your_organization/ontoportal-configs.git'
desc "Check if agent forwarding is working"
task :forwarding do
  on roles(:all) do |h|
    if test("env | grep SSH_AUTH_SOCK")
      info "Agent forwarding is up to #{h}"
    else
      error "Agent forwarding is NOT up to #{h}"
    end
  end
end

# inspired by http://nathaniel.talbott.ws/blog/2013/03/14/post-deploy-smoke-tests/
desc 'Run smoke test'
task :smoke_test do
  on roles(:app) do
    curl_opts = '--max-time 240 --connect-timeout 15 --retry 2'
    failed_tests = []
    curl_result = `curl #{curl_opts} -s -w "%{http_code}" "#{host}/documentation" -o /dev/null`
    failed_tests << 'Documentation smoke test FAILURE.' unless (curl_result == '200')

    if defined?(APIKEY)
      curl_result = `curl #{curl_opts} -s -w "%{http_code}" "#{host}/ontologies?include=all&include_views=true&apikey=#{APIKEY}" -o /dev/null`
      failed_tests << 'Ontologies smoke test FAILURE.' unless (curl_result == '200')
    end
    if failed_tests.empty?
      puts "smoke test passed on #{host}"
    else
      puts "\n\n****************************\n\n"
      puts "SMOKE TEST FAILED on #{host}\n\n"
      failed_tests.each do |failure|
        puts failure
      end
      puts "\n\n****************************\n\n"
    end
  end
end

namespace :deploy do

  desc 'Incorporate the private repository content'
  # Get cofiguration from repo if PRIVATE_CONFIG_REPO env var is set
  # or get config from local directory if LOCAL_CONFIG_PATH env var is set
  task :get_config do
    if defined?(PRIVATE_CONFIG_REPO)
      TMP_CONFIG_PATH = "/tmp/#{SecureRandom.hex(15)}".freeze
      on roles(:app) do
        execute "git clone -q #{PRIVATE_CONFIG_REPO} #{TMP_CONFIG_PATH}"
        execute "rsync -av #{TMP_CONFIG_PATH}/#{fetch(:config_folder_path)}/ #{release_path}/"
        execute "rm -rf #{TMP_CONFIG_PATH}"
      end
    elsif defined?(LOCAL_CONFIG_PATH)
      on roles(:app) do
        execute "rsync -av #{LOCAL_CONFIG_PATH}/#{fetch(:application)}/ #{release_path}/"
      end
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
      execute 'sudo systemctl restart unicorn'
      execute 'sleep 5'
    end
  end

  after :updating, :get_config
  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end
end
