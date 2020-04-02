# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary
# server in each group is considered to be the first
# unless any hosts have the primary property set.
# Don't declare `role :all`, it's a meta role

# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server
# definition into the server list. The second argument
# something that quacks like a hash can be used to set
# extended properties on the server.
server 'localhost', roles: %w{app}

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

NCBO_BRANCH = ENV.include?('NCBO_BRANCH') ? ENV['NCBO_BRANCH'] : 'master'
set :branch, "#{NCBO_BRANCH}"
set :deploy_to, "/srv/ontoportal/#{fetch(:application)}"

# private git repo for configuraiton
# PRIVATE_CONFIG_REPO = ENV.include?('PRIVATE_CONFIG_REPO') ? ENV['PRIVATE_CONFIG_REPO'] : 'git@github.com:your_org/private-config-repo.git'

# location of local configuration files
LOCAL_CONFIG_PATH = ENV.include?('LOCAL_CONFIG_PATH') ? ENV['LOCAL_CONFIG_PATH'] : '/srv/ontoportal/virtual_appliance/appliance_config'
