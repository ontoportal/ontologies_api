# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary
# server in each group is considered to be the first
# unless any hosts have the primary property set.
# Don't declare `role :all`, it's a meta role
role :app, %w{testportal.lirmm.fr}
role :db, %w{testportal.lirmm.fr} # sufficient to run db:migrate only on one system
# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server
# definition into the server list. The second argument
# something that quacks like a hash can be used to set
# extended properties on the server.
#server 'example.com', user: 'deploy', roles: %w{web app}, my_property: :my_value
set :log_level, :error
set :branch, ENV.include?('BRANCH') ? ENV['BRANCH'] : 'test'
