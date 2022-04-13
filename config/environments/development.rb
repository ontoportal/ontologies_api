# This file can be copied and renamed to match the environment you are running in:
#   production.rb
#   development.rb
#   test.rb
# This file is designed to be used for developement with docker-compose
#

GOO_PATH_QUERY   = ENV.include?("GOO_PATH_QUERY")   ? ENV["GOO_PATH_QUERY"]   : "/sparql/"
GOO_PATH_DATA    = ENV.include?("GOO_PATH_DATA")    ? ENV["GOO_PATH_DATA"]    : "/data/"
GOO_PATH_UPDATE  = ENV.include?("GOO_PATH_UPDATE")  ? ENV["GOO_PATH_UPDATE"]  : "/update/"
GOO_BACKEND_NAME = ENV.include?("GOO_BACKEND_NAME") ? ENV["GOO_BACKEND_NAME"] : "localhost"
GOO_PORT         = ENV.include?("GOO_PORT")         ? ENV["GOO_PORT"]         : 9000
GOO_HOST         = ENV.include?("GOO_HOST")         ? ENV["GOO_HOST"]         : "localhost"
REDIS_HOST       = ENV.include?("REDIS_HOST")       ? ENV["REDIS_HOST"]       : "localhost"
REDIS_PORT       = ENV.include?("REDIS_PORT")       ? ENV["REDIS_PORT"]       : 6379
MGREP_HOST       = ENV.include?("MGREP_HOST")       ? ENV["MGREP_HOST"]       : "localhost"
MGREP_PORT       = ENV.include?("MGREP_PORT")       ? ENV["MGREP_PORT"]       : 55555
SOLR_TERM_SEARCH_URL = ENV.include?("SOLR_TERM_SEARCH_URL") ? ENV["SOLR_TERM_SEARCH_URL"] : "http://localhost:8983/solr/term_search_core1"
SOLR_PROP_SEARCH_URL = ENV.include?("SOLR_PROP_SEARCH_URL") ? ENV["SOLR_PROP_SEARCH_URL"] : "http://localhost:8983/solr/prop_search_core1"

LinkedData.config do |config|
  config.goo_host                      = GOO_HOST.to_s
  config.goo_port                      = GOO_PORT.to_i
  config.goo_redis_host                = REDIS_HOST.to_s
  config.goo_redis_port                = REDIS_PORT.to_i
  config.http_redis_host               = REDIS_HOST.to_s
  config.http_redis_port               = REDIS_PORT.to_i
  config.ontology_analytics_redis_host = REDIS_HOST.to_s
  config.ontology_analytics_redis_port = REDIS_PORT.to_i
  config.search_server_url             = SOLR_TERM_SEARCH_URL.to_s
  config.property_search_server_url    = SOLR_PROP_SEARCH_URL.to_s
  config.repository_folder = File.expand_path("../../../test/data/uploaded_ontologies", __FILE__)
  # config.rest_url_prefix = "http://data.bioontology.org/"
  config.rest_url_prefix = "http://localhost:9393/"
  config.replace_url_prefix = true
#  config.enable_notifications          = false
end

Annotator.config do |config|
  config.annotator_redis_host    = REDIS_HOST.to_s
  config.annotator_redis_port    = REDIS_PORT.to_i
  config.mgrep_host              = MGREP_HOST.to_s
  config.mgrep_port              = MGREP_PORT.to_i
  config.mgrep_dictionary_file   = "./test/data/dictionary.txt"
  config.stop_words_default_file = "./config/default_stop_words.txt"
end

OntologyRecommender.config do |config|
end

LinkedData::OntologiesAPI.config do |config|
  config.http_redis_host   = REDIS_HOST.to_s
  config.http_redis_port   = REDIS_PORT.to_i
  config.restrict_download = ["ACR0", "ACR1", "ACR2"]
end

NcboCron.config do |config|
  config.redis_host = REDIS_HOST.to_s
  config.redis_port = REDIS_PORT.to_i
end
