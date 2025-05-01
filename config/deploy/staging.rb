# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary
# server in each group is considered to be the first
# unless any hosts have the primary property set.
# Don't declare `role :all`, it's a meta role
role :app, %w{ncbostage-rest1.stanford.edu ncbostage-rest2.stanford.edu ncbostage-rest3.stanford.edu}

# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server
# definition into the server list. The second argument
# something that quacks like a hash can be used to set
# extended properties on the server.
# server 'example.com', user: 'deploy', roles: %w{web app}, my_property: :my_value

# you can set custom ssh options
# it's possible to pass any option but you need to keep in mind that net/ssh understand limited list of options
# you can see them in [net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start)
# set it globally
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
# and/or per server
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
# setting per server overrides global ssh_options

# supress output, no need to know about which server we are connecting to
set :log_level, :error

# set git branch to deploy from.  Default to master in produciton
# this can be overwritten with a different branch or tag, i.e v6.9.0 by setting env variable BRANCH
BRANCH = ENV.include?('BRANCH') ? ENV['BRANCH'] : 'master'
set :branch, BRANCH

set :ssh_options, {
  user: 'ncbo-deployer',
  forward_agent: 'true', # forward agent is required for accessing private config repo
  # ssh keys which grant access to private repo and deployer user on the UI systems
  keys: %w(/var/lib/jenkins/.ssh/id_rsa-ncbo-deployer config/deploy_id_rsa),
  auth_methods: %w(publickey),
  # UI servers are not accessible by github so we need to just jumphost to get to them
  proxy: Net::SSH::Proxy::Command.new('ssh ncbo-deployer@sftp.bmir.stanford.edu -W %h:%p')
}

# private git repo containing custom configuraiton
# private repo has to be either in the form of `git@github.com:author/config_repo_name.git`
# or https://user:PAT@github.com/author/config_repo_name.git.  Using http with PAT is
# less insecure since this file will reside on the server but ssh agent session is active
# for a short period of time during deployments.

PRIVATE_CONFIG_REPO = ENV.include?('PRIVATE_CONFIG_REPO') ? ENV['PRIVATE_CONFIG_REPO'] : 'git@github.com:ncbo/bioportal_config.git'