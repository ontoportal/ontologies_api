class MetricsController < ApplicationController
  namespace "/metrics" do

    # Display all metrics
    get do
      check_last_modified_collection(LinkedData::Models::Metrics)
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
    ont, sub = get_ontology_and_submission
    ont = Ontology.find(params["ontology"]).first
    sub.bring(metrics: LinkedData::Models::Metrics.attributes)
    reply sub.metrics
  end

  get "/ontologies/:ontology/submissions/:submissionId/metrics" do 
    ont, sub = get_ontology_and_submission
    ont = Ontology.find(params["ontology"]).first
    sub.bring(metrics: LinkedData::Models::Metrics.attributes)
    if sub.metrics.nil?
      error(404) 
    else
      reply sub.metrics
    end
  end

end
