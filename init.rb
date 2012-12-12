# Recursively require files from directories and their sub-directories
def require_dir(dir)
  Dir.glob("#{dir}/*.rb").each {|f| require_relative f }
  Dir.glob("#{dir}/*/").each {|d| require_dir(d.gsub(/\/+$/, '')) }
end

# Require controller base files
require_relative "controllers/application_controller"

# Require known directories
require_dir("lib")
require_dir("helpers")
require_dir("models")
require_dir("controllers")

# Setup ontologies_linked_data connection to triplestore
LinkedData.config