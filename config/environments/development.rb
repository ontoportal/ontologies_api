begin
  LinkedData.config do |config|
    # config.goo_host           = "ncbostage-4store1"
    config.goo_host           = "ncboprod-4store1"
    config.goo_port           = 8080


    # AG
    # config.goo_backend_name  = "AG"
    # # config.goo_host          = "localhost"
    # config.goo_host          = "192.168.0.105"
    # # config.goo_host          = "ncbo-dev-ci-03.stanford.edu"
    # config.goo_port          = 10035
    # config.goo_path_query    = "/repositories/ontoportal"
    # config.goo_path_data     = "/repositories/ontoportal/statements"
    # config.goo_path_update   = "/repositories/ontoportal/statements"





    # config.search_server_url  = "http://ncbostage-solr2.stanford.edu:8983/solr/term_search_core1"
    # config.property_search_server_url  = "http://ncbostage-solr2.stanford.edu:8983/solr/prop_search_core1"
    config.search_server_url  = "http://ncboprod-solr2.stanford.edu:8983/solr/term_search_core1"
    config.property_search_server_url  = "http://ncboprod-solr2.stanford.edu:8983/solr/prop_search_core1"
    # config.search_server_url  = "http://localhost:8983/solr/term_search_core1"
    # config.property_search_server_url  = "http://localhost:8983/solr/prop_search_core1"

    config.repository_folder  = "/Users/mdorf/dev/ncbo/test/repo"
    # config.rest_url_prefix    = "http://data.bioontology.org/"
    config.rest_url_prefix    = "http://localhost:9393/"





    config.enable_security    = false




    # config.apikey             = "24e0e77e-54e0-11e0-9d7b-005056aa3316"
    config.apikey             = "24e0d93c-54e0-11e0-9d7b-005056aa3316"



    config.enable_http_cache  = false




    config.replace_url_prefix = true


    # config.goo_redis_host     = "ncbostage-redis3"
    config.goo_redis_host     = "ncboprod-redis3"
    # config.goo_redis_host     = "ncbo-prd-rds-03.sunet"
    config.goo_redis_port     = 6381
    # config.goo_redis_host     = "localhost"
    # config.goo_redis_port     = 6379

    # config.http_redis_host    = "ncbostage-redis2"
    config.http_redis_host    = "ncboprod-redis2"
    # config.http_redis_host    = "ncbo-prd-rds-02.sunet"
    config.http_redis_port    = 6380
    # config.http_redis_host     = "localhost"
    # config.http_redis_port     = 6379

    config.ui_host            = "bioportal.bioontology.org"
    config.enable_slices      = true

    # PURL server config parameters
    config.enable_purl            = true
    config.purl_host              = "purl.bioontology.org"
    config.purl_port              = 80
    config.purl_username          = "bioportal-admin"
    config.purl_password          = "purl-admin"
    config.purl_maintainers       = "bioportal-admin,nigam,natasha"
    config.purl_target_url_prefix = "http://bioportal.bioontology.org"


    #Ontology Analytics Redis
    # config.ontology_analytics_redis_host = "ncbostage-redis1"
    config.ontology_analytics_redis_host = "ncboprod-redis1"
    # config.ontology_analytics_redis_host = "ncbo-prd-rds-01.sunet"
    # config.ontology_analytics_redis_host = "localhost"
    config.ontology_analytics_redis_port = 6379
  end
rescue NameError
  puts "(CNFG) >> LinkedData not available, cannot load config"
end

begin
  Annotator.config do |config|
    config.mgrep_dictionary_file   = "./test/data/dictionary.txt"
    config.stop_words_default_file = "./config/default_stop_words.txt"
    # config.mgrep_host              = "ncbostage-mgrep1"
    config.mgrep_host              = "ncboprod-mgrep1"
    config.mgrep_port              = 55555
    # config.mgrep_host              = "ncbostage-mgrep2"
    config.mgrep_alt_host          = "ncboprod-mgrep2"
    config.mgrep_alt_port          = 55555

    # config.annotator_redis_host    = "localhost"
    # config.annotator_redis_host    = "ncbostage-redis1"
    config.annotator_redis_host    = "ncboprod-redis1"
    # config.annotator_redis_host    = "ncbo-prd-rds-01.sunet"
    # config.annotator_redis_host    = "localhost"
    config.annotator_redis_port    = 6379
  end
rescue NameError
  puts "(CNFG) >> Annotator not available, cannot load config"
end

begin
  OntologyRecommender.config do |config|
  end
rescue NameError
  puts "(CNFG) >> OntologyRecommender not available, cannot load config"
end

begin
  LinkedData::OntologiesAPI.config do |config|
    config.enable_unicorn_workerkiller = false
    config.enable_throttling           = false
    config.resolver_redis_host = "ncbostage-redis2"
    # config.resolver_redis_host = "ncboprod-redis2"
    config.resolver_redis_port = 6379
    config.http_redis_host     = LinkedData.settings.http_redis_host
    config.http_redis_port     = LinkedData.settings.http_redis_port
    config.restrict_download   = ['CPT','ICD10','ICNP','ICPC2P','MDDB','MEDDRA','MSHFRE','MSHSPA_1','NDDF','NDFRT','NIC','ONTOPSYCHIA','RCD','SCTSPA','SNOMEDCT','WHO-ART']
  end
rescue NameError
  puts "(CNFG) >> OntologiesAPI not available, cannot load config"
end

begin
  NcboCron.config do |config|
    config.redis_host           = Annotator.settings.annotator_redis_host
    config.redis_port           = Annotator.settings.annotator_redis_port
    config.enable_pull_umls     = false

    # config.search_index_all_url  = "http://ncbostage-solr2.stanford.edu:8983/solr/term_search_core2"
    # config.property_search_index_all_url  = "http://ncbostage-solr2.stanford.edu:8983/solr/prop_search_core2"
    config.search_index_all_url  = "http://ncboprod-solr2.stanford.edu:8983/solr/term_search_core2"
    config.property_search_index_all_url  = "http://ncboprod-solr2.stanford.edu:8983/solr/prop_search_core2"

    config.ontology_report_path = "/Users/mdorf/dev/ncbo/test/reports/ontologies_report.json"

    config.versions_file_path = "../ncbo_cron/versions"



    config.update_check_endpoint_url = "http://localhost:9393/admin/latestversion"
    # config.update_check_endpoint_url = "http://updatecheck.bioontology.org/latestversion"


    # Google Analytics config
    config.analytics_service_account_email_address = "456709209738-titiphe0gm6r0vrfnhlu91dj4kpvoj8e@developer.gserviceaccount.com"
    config.analytics_path_to_key_file              = "config/bioportal-analytics.p12"
    config.analytics_profile_id                    = "ga:8273133"
    config.analytics_app_name                      = "BioPortal"
    config.analytics_app_version                   = "1.0.0"
    config.analytics_start_date                    = "2018-10-01"
    config.analytics_filter_str                    = "ga:networkLocation!@stanford;ga:networkLocation!@amazon"



  end
rescue NameError
  puts "(CNFG) >> NcboCron not available, cannot load config"
end

# begin
#   ResourceIndex.config({
#                            username: "ri-api",
#                            password: "riapi",
#                            host: "ncboprod-ridb1.sunet",
#                            es_hosts: ["ncbo-prd-es-01", "ncbo-prd-es-02", "ncbo-prd-es-03"]
#                        })
# rescue NameError
#   puts "(CNFG) >> ResourceIndex not available, cannot load config"
# end

Goo.use_cache = false


# LinkedData.config do |config|
#   config.goo_host           = "ncboprod-4store1"
#   # config.goo_host           = "ncbostage-4store1"
#   config.goo_port           = 8080
#
#   config.search_server_url  = "http://ncboprod-solr2.stanford.edu:8983/solr/core1"
#   # config.search_server_url  = "http://ncbostage-solr2.stanford.edu:8983/solr/core1"
#   # config.search_server_url = "http://localhost:8983/solr/NCBO1"
#
#   config.repository_folder = "/Users/mdorf/dev/ncbo/test/repo"
#
#   # config.rest_url_prefix    = "http://stagedata.bioontology.org/"
#   config.rest_url_prefix    = "http://localhost:9393/"
#
#
#   config.enable_security    = false
#   config.enable_http_cache  = true
#
#
#
#
#   config.replace_url_prefix = true
#
#
#
#
#   config.goo_redis_host     = "ncboprod-redis3"
#   # config.goo_redis_host     = "ncbostage-redis2"
#
#   # config.goo_redis_host     = "localhost"
#   # config.goo_redis_port     = 6379
#
#
#   config.goo_redis_port     = 6381
#
#
#   config.http_redis_host    = "ncboprod-redis2"
#   # config.http_redis_host    = "ncbostage-redis1"
#   config.http_redis_port    = 6380
#
#   # config.http_redis_host     = "localhost"
#   # config.http_redis_port     = 6379
#
#
#
#   # config.apikey             = "24e0e77e-54e0-11e0-9d7b-005056aa3316"
#   config.ui_host            = "ncbo-prd-app-18.stanford.edu"
#
#   # PURL server config parameters
#   config.enable_purl            = false
#   # config.purl_host              = "purl.bioontology.org"
#   config.purl_host              = "stagepurl.bioontology.org"
#   config.purl_port              = 80
#   config.purl_username          = "bioportal-admin"
#   config.purl_password          = "purl-admin"
#   config.purl_maintainers       = "bioportal-admin,nigam,natasha"
#   config.purl_target_url_prefix = "http://bioportal.bioontology.org"
#   # config.purl_target_url_prefix = "http://stage.bioontology.org"
#
#   # Ontology Analytics Redis
#   config.ontology_analytics_redis_host = "ncboprod-redis1"
#   # config.ontology_analytics_redis_host = "ncbostage-redis1"
#   config.ontology_analytics_redis_port = 6379
#
#   config.enable_slices      = true
# end
#
# Annotator.config do |config|
#   config.mgrep_dictionary_file   = "./test/data/dictionary.txt"
#   # config.mgrep_host              = "ncbostage-mgrep2"
#   config.mgrep_host              = "ncboprod-mgrep1"
#   config.mgrep_port              = 55555
#   # config.mgrep_alt_host          = "ncbostage-mgrep3"
#   config.mgrep_alt_host          = "ncboprod-mgrep2"
#   config.mgrep_alt_port          = 55555
#
#   # config.annotator_redis_host    = "ncbostage-redis1"
#   config.annotator_redis_host    = "ncboprod-redis1"
#   config.annotator_redis_port    = 6379
#   config.enable_recognizer_param = true
#   config.supported_recognizers = [:mgrep, :mallet]  # :mgrep, :mallet
# end
#
# OntologyRecommender.config do |config|
# end
#
# LinkedData::OntologiesAPI.config do |config|
#   config.enable_monitoring   = true
#   config.cube_host           = "192.241.195.36"
#
#   config.resolver_redis_host = "ncboprod-redis2"
#   # config.resolver_redis_host = "ncbostage-redis2"
#   config.resolver_redis_port = 6379
#
#
#
#
#
#
#   config.http_redis_host     = "ncboprod-redis2"
#   # config.http_redis_host     = "ncbostage-redis1"
#   config.http_redis_port     = 6380
#
# end
#
# NcboCron.config do |config|
#   # Ontologies Report config
#   config.ontology_report_path = "/Users/mdorf/dev/ncbo/test/reports/ontologies_report.json"
#   config.redis_host = Annotator.settings.annotator_redis_host
#   config.redis_port = Annotator.settings.annotator_redis_port
#
#   # Google Analytics config
#   config.analytics_service_account_email_address = "456709209738-titiphe0gm6r0vrfnhlu91dj4kpvoj8e@developer.gserviceaccount.com"
#   config.analytics_path_to_key_file              = "config/bioportal-analytics.p12"
#   config.analytics_profile_id                    = "ga:8273133"
#   config.analytics_app_name                      = "BioPortal"
#   config.analytics_app_version                   = "1.0.0"
#   config.analytics_start_date                    = "2013-10-01" # October 1st, 2013 - the date of the new API
#   config.analytics_filter_str                    = "ga:networkLocation!@stanford;ga:networkLocation!@amazon"
# end
#
# Goo.use_cache = true