# This is the base class for controllers in the application.
# Code in the before or after blocks will run on every request
class ApplicationController < Sinatra::Base
  before {
    # Run before route
  }

  after {
    # Run after route
  }
end