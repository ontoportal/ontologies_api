# This is the folder where uploaded ontology files are stored
$REPOSITORY_FOLDER = File.expand_path('../../../test/data/uploaded_ontologies', __FILE__)


local_path = File.expand_path("../local/development.rb", __FILE__)
require local_path if File.exist?(local_path)
