#!/bin/bash
# generates solr configsets by merging _default configset with config files in config/solr
# _default is copied from sorl distribuion solr-8.10.1/server/solr/configsets/_default/

pushd solr/configsets
ld_config='../../../../ontologies_linked_data/config/solr/'
#ld_config='../../../../config/solr/'
ls -l $ld_config
pwd
[ -d property_search ] && rm -Rf property_search
[ -d term_search ] && rm -Rf property_search
[ -d $ld_config/property_search ] || echo "cant find ontologies_linked_data project" 
mkdir -p property_search/conf
mkdir -p term_search/conf
cp -a _default/conf/* property_search/conf/
cp -a _default/conf/* term_search/conf/
cp -a $ld_config/property_search/* property_search/conf
cp -a $ld_config/term_search/* term_search/conf
popd
