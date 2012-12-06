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


# Get an array of constants that are subclasses for a given class
def subclasses_for(klass)
  ObjectSpace.enum_for(:each_object, class << klass; self; end).to_a
end

# Load controllers. This is so we can define routes in multiple files.
subclasses_for(ApplicationController).each do |sub|
  use sub
end

