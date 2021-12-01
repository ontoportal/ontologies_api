require 'logger'
require 'ontologies_linked_data'
require 'ncbo_annotator'
require_relative 'config/config'
#require_relative 'config/environments/production'
require_relative 'config/environments/development.rb.sample'

logger = Logger.new("indexing.log")

# clear the index
logger.info("Clearing existing index.")
LinkedData::Models::Class.indexClear()
LinkedData::Models::Class.indexCommit()

only_index = ["TAO", "VHOG", "QIBO", "SDO", "XAO", "GLOB", "DEMOGRAPH", "BHO", "FMA-SUBSET", "RCD"]
# only_index = ["FMA-SUBSET"]
# only_index = []

logger.info("Began indexing ontologies...")
submissions = LinkedData::Models::OntologySubmission.where(submissionStatus: [code: "RDF"]).include(:submissionId, ontology: LinkedData::Models::Ontology.attributes).all

submissions.each do |s|
  if only_index.empty? || only_index.include?(s.ontology.acronym)
    begin
      s.process_submission(logger,
                           process_rdf: false,
                           index_search: true, index_commit: true,
                           run_metrics: false, reasoning: false)
    rescue Exception => e
      logger.error e
    end
  end
end

logger.info("Completed indexing ontologies.")
logger.info("Optimizing index...")
LinkedData::Models::Class.indexOptimize()
logger.info("Completed optimizing index.")
