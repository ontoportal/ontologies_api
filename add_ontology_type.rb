require 'ontologies_linked_data'
require 'ncbo_annotator'
require 'ncbo_ontology_recommender'
require 'ncbo_cron'
require_relative 'config/config'
# require_relative 'config/environments/production'
# require_relative 'config/environments/stage'
require_relative 'config/environments/development'


value_set_collections = ["NLMVS", "CEDARVS"]
type_vs = LinkedData::Models::OntologyType.find(RDF::URI.new("http://data.bioontology.org/ontology_types/VALUE_SET_COLLECTION")).first
type_ont = LinkedData::Models::OntologyType.find(RDF::URI.new("http://data.bioontology.org/ontology_types/ONTOLOGY")).first


# acronyms = ["iceci-details_for_activity", "Radlex3.9.1", "SNOMED-Ethnic-Group", "TM-SIGNS-AND-SYMPTS", "iceci-details_for_mechanism", "iceci-substance_use", "iceci-descriptor_for_intent", "iceci-instrument_object_substance", "H2_HIPClassicRegions", "iceci-countermeasures", "iceci-details_for_place_of_occurrence", "H3_HIPSeptotemporalAxis", "HOM-UCSF_UCareDispostion", "BRO-AreaOfResearch", "iceci-place_of_occurrence"]


LinkedData::Models::Ontology.all.each do |ont|
  ont.bring_remaining
  acronym = ont.acronym


  # next unless acronyms.empty? || acronyms.include?(acronym)

  # if value_set_collections.include? acronym
  #   ont.ontologyType = type_vs
  # else
  #   ont.ontologyType = type_ont
  # end



  # ont.ontologyType = type_ont if ont.ontologyType.nil?

  if ont.ontologyType.nil?
    ont.ontologyType = type_ont

    puts "no ontology type: #{acronym}"
    puts "#{acronym}: #{ont.valid?} - #{ont.errors}"
    # binding.pry

    ont.save if ont.valid?


  end


end

# acronyms.each do |acronym|
#   purl_client.fix_purl(acronym)
# end
