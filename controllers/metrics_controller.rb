class MetricsController
  namespace "/metrics" do
    # Display all metrics
    get do
    end
  end

  # Display metrics for ontology
  get "/ontologies/:ontology/metrics" do
  end

end