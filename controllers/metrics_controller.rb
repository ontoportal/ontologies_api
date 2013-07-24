class MetricsController < ApplicationController
  namespace "/metrics" do

    # Display all metrics
    get do
      submissions = retrieve_latest_submissions
      submissions = submissions.values
      LinkedData::Models::OntologySubmission.where.models(submissions)
                         .include(metrics: (LinkedData::Models::Metrics.attributes << :submission))
                               .all
      reply submissions.select { |s| !s.metrics.nil? }.map { |s| s.metrics }
    end

  end

  # Display metrics for ontology
  get "/ontologies/:ontology/metrics" do
    ont = Ontology.find(params["ontology"]).first
    error 404, "You must provide a valid `acronym` to retrieve an ontology" if ont.nil?
    sub = ont.latest_submission
    error 404, "The ontology with acronym `#{acr}` does not have any parsed submissions" if sub.nil?
    sub.bring(metrics: LinkedData::Models::Metrics.attributes)
    reply sub.metrics
  end

end
