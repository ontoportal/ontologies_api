class MetricsController < ApplicationController
  namespace "/metrics" do
    # Default content type (this will need to support all of our content types eventually)
    before { content_type :json }

    # Display all metrics
    get do
    end
  end

  # Display metrics for ontology
  get "/ontologies/:ontology/metrics" do
  end

end