# This is the folder where uploaded ontology files are stored
$REPOSITORY_FOLDER = File.expand_path('../../../test/data/uploaded_ontologies', __FILE__)

require_relative "local/development.rb" if File.exist?("local/development.rb")
