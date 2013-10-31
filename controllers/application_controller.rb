# This is the base class for controllers in the application.
# Code in the before or after blocks will run on every request
class ApplicationController
  include Sinatra::Delegator
  extend Sinatra::Delegator

  # Run before route
  before {
  }

  # Run after route
  after {
  }

end
