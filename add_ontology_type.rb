require 'ontologies_linked_data'
require 'ncbo_annotator'
require_relative 'config/config'
# require_relative 'config/environments/production'
require_relative 'config/environments/stage'


value_set_collections = ["NLMVS", "CEDARVS"]
type_vs = LinkedData::Models::OntologyType.find(RDF::URI.new("http://data.bioontology.org/ontology_types/VALUE_SET_COLLECTION")).first
type_ont = LinkedData::Models::OntologyType.find(RDF::URI.new("http://data.bioontology.org/ontology_types/ONTOLOGY")).first

binding.pry


LinkedData::Models::Ontology.all.each do |ont|
  ont.bring_remaining
  acronym = ont.acronym

  if value_set_collections.include? acronym
    ont.ontologyType = type_vs
  else
    ont.ontologyType = type_ont
  end

  # ont.save if ont.valid?
end




# acronyms.each do |acronym|
#   purl_client.fix_purl(acronym)
# end
