# This is the base class for controllers in the application.
# Code in the before or after blocks will run on every request
class ApplicationController
  include Sinatra::Delegator
  extend Sinatra::Delegator

  # Restrict downloads for ontologies with licensing restrictions.
  # Used in ontologies_controller and ontology_submissions_controller
  ONT_RESTRICT_DOWNLOADS = LinkedData::OntologiesAPI.settings.restrict_download

  # Run before route
  before {
  }

  # Run after route
  after {
  }

end
