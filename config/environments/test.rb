# This file is designed to be used for unit testing with docker-compose

GOO_BACKEND_NAME = ENV.include?("GOO_BACKEND_NAME") ? ENV["GOO_BACKEND_NAME"] : "4store"
GOO_PATH_QUERY = ENV.include?("GOO_PATH_QUERY") ? ENV["GOO_PATH_QUERY"] : "/sparql/"
GOO_PATH_DATA = ENV.include?("GOO_PATH_DATA") ? ENV["GOO_PATH_DATA"] : "/data/"
GOO_PATH_UPDATE = ENV.include?("GOO_PATH_UPDATE") ? ENV["GOO_PATH_UPDATE"] : "/update/"
GOO_PORT = ENV.include?("GOO_PORT") ? ENV["GOO_PORT"] : 9000
GOO_HOST = ENV.include?("GOO_HOST") ? ENV["GOO_HOST"] : "localhost"
REDIS_HOST = ENV.include?("REDIS_HOST") ? ENV["REDIS_HOST"] : "localhost"
REDIS_PORT = ENV.include?("REDIS_PORT") ? ENV["REDIS_PORT"] : 6379
SOLR_TERM_SEARCH_URL = ENV.include?("SOLR_TERM_SEARCH_URL") ? ENV["SOLR_TERM_SEARCH_URL"] : "http://localhost:8983/solr"
SOLR_PROP_SEARCH_URL = ENV.include?("SOLR_PROP_SEARCH_URL") ? ENV["SOLR_PROP_SEARCH_URL"] : "http://localhost:8983/solr"
MGREP_HOST = ENV.include?("MGREP_HOST") ? ENV["MGREP_HOST"] : "localhost"
MGREP_PORT = ENV.include?("MGREP_PORT") ? ENV["MGREP_PORT"] : 55556
GOO_SLICES = ENV["GOO_SLICES"] || 500

begin
  # For prefLabel extract main_lang first, or anything if no main found.
  # For other properties only properties with a lang that is included in main_lang are used
  Goo.main_languages = ['en']
  Goo.use_cache = false
  Goo.slice_loading_size = GOO_SLICES.to_i
rescue NoMethodError
  puts "(CNFG) >> Goo.main_lang not available"
end

LinkedData.config do |config|
  config.goo_backend_name = GOO_BACKEND_NAME.to_s
  config.goo_host = GOO_HOST.to_s
  config.goo_port = GOO_PORT.to_i
  config.goo_path_query = GOO_PATH_QUERY.to_s
  config.goo_path_data = GOO_PATH_DATA.to_s
  config.goo_path_update = GOO_PATH_UPDATE.to_s
  config.goo_redis_host = REDIS_HOST.to_s
  config.goo_redis_port = REDIS_PORT.to_i
  config.http_redis_host = REDIS_HOST.to_s
  config.http_redis_port = REDIS_PORT.to_i
  config.ontology_analytics_redis_host = REDIS_HOST.to_s
  config.ontology_analytics_redis_port = REDIS_PORT.to_i
  config.search_server_url = SOLR_TERM_SEARCH_URL.to_s
  config.property_search_server_url = SOLR_PROP_SEARCH_URL.to_s
  config.sparql_endpoint_url = "http://sparql.bioontology.org"
  #  config.enable_notifications          = false
  config.interportal_hash = {
    "agroportal" => {
      "api" => "http://data.agroportal.lirmm.fr",
      "ui" => "http://agroportal.lirmm.fr",
      "apikey" => "1cfae05f-9e67-486f-820b-b393dec5764b"
    },
    "ncbo" => {
      "api" => "http://data.bioontology.org",
      "apikey" => "4a5011ea-75fa-4be6-8e89-f45c8c84844e",
      "ui" => "http://bioportal.bioontology.org",
    },
    "sifr" => {
      "api" => "http://data.bioportal.lirmm.fr",
      "ui" => "http://bioportal.lirmm.fr",
      "apikey" => "1cfae05f-9e67-486f-820b-b393dec5764b"
    }
  }
  config.oauth_providers = {
    github: {
      check: :access_token,
      link: 'https://api.github.com/user'
    },
    keycloak: {
      check: :jwt_token,
      cert: 'KEYCLOAK_SECRET_KEY'
    },
    orcid: {
      check: :access_token,
      link: 'https://pub.orcid.org/v3.0/me'
    },
    google: {
      check: :access_token,
      link: 'https://www.googleapis.com/oauth2/v3/userinfo'
    }
  }
end

Annotator.config do |config|
  config.annotator_redis_host = REDIS_HOST.to_s
  config.annotator_redis_port = REDIS_PORT.to_i
  config.mgrep_host = MGREP_HOST.to_s
  config.mgrep_port = MGREP_PORT.to_i
  config.mgrep_dictionary_file = "./test/data/dictionary.txt"
end

OntologyRecommender.config do |config|
end

LinkedData::OntologiesAPI.config do |config|
  config.http_redis_host = REDIS_HOST.to_s
  config.http_redis_port = REDIS_PORT.to_i
end

NcboCron.config do |config|
  config.redis_host = REDIS_HOST.to_s
  config.redis_port = REDIS_PORT.to_i
end
