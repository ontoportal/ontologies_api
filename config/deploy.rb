# config valid only for Capistrano 3.4+
#lock '3.7.1'

APP_PATH='/srv/ncbo'

set :application, 'ontologies_api'
set :repo_url, "git://github.com/ncbo/#{fetch(:application)}.git"

set :deploy_via, :remote_cache

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
set :deploy_to, "#{APP_PATH}/#{fetch(:application)}"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
#set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
set :linked_dirs, %w{log tmp/pids tmp/sockets vendor/bundle public/system}

# rbenv
#set :rbenv_type, :system #or :user
#set :rbenv_ruby, '2.0.0-p353'
#set :rbenv_roles, :all # default value

# do not use sudo
set :use_sudo, false

# Default value for default_env is {}
set :default_env, { 
}

# Default value for keep_releases is 5
set :keep_releases, 5

namespace :deploy do
  desc 'display remote system shell environment variables'
  task :puts_remote_env do
    on roles(:all) do
      puts "deploying #{fetch(:branch)} branch/tag"
      remote_env = capture("env")
      puts remote_env
    end
  end

  desc 'Incorporate the bioportal_conf private repository content'
  #Get cofiguration from repo if PRIVATE_CONFIG_REPO env var is set 
  #or get config from local directory if LOCAL_CONFIG_PATH env var is set 
  task :get_config do
     if defined?(PRIVATE_CONFIG_REPO)
       on roles(:app, :web) do
          TMP_CONFIG_PATH = "/tmp/#{SecureRandom.hex(15)}"
          execute "git clone -q #{PRIVATE_CONFIG_REPO} #{TMP_CONFIG_PATH}"
          execute "rsync -av #{TMP_CONFIG_PATH}/#{fetch(:application)}/ #{release_path}/"
          execute "rm -rf #{TMP_CONFIG_PATH}"
       end
     elsif defined?(LOCAL_CONFIG_PATH)
       on roles(:app, :web) do
          execute "rsync -av #{LOCAL_CONFIG_PATH}/#{fetch(:application)}/ #{release_path}/"
       end
     end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
      execute "/etc/init.d/unicorn restart"
      execute "sleep 10"
    end
  end

  after :updating, :get_config
  after :publishing, :restart

#  after :restart, :clear_cache do
#    on roles(:web), in: :groups, limit: 3, wait: 10 do
#       Here we can do anything such as:
#       within release_path do
#         execute :rake, 'cache:clear'
#       end
#    end
#  end
end
