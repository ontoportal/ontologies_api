# This is the base class for controllers in the application.
# Code in the before or after blocks will run on every request
class ApplicationController
  include Sinatra::Delegator
  extend Sinatra::Delegator

  # TODO: Also check for licensing restrictions, see
  # TODO: https://bmir-jira.stanford.edu/browse/NCBO-331
  # TODO: Revise this code if/when the ontology model contains license attributes
  # TODO: to be used for access filtering on downloads.
  # Used in ontologies_controller and ontology_submissions_controller
  ONT_RESTRICT_DOWNLOADS = ['NDFRT',
                            'SNOMEDCT',
                            'WHO-ART',
                            'NDDF',
                            'MDDB',
                            'RCD',
                            'NIC',
                            'ICPC2P',
                            'SCTSPA',
                            'MSHSPA_1',
                            'MEDDRA',
                            'NDDF',
                            'MSHFRE']

  # Run before route
  before {
  }

  # Run after route
  after {
  }

end
