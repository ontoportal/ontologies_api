class MetricsController < ApplicationController
  namespace "/metrics" do

    # Display all metrics
    get do
      check_last_modified_collection(LinkedData::Models::Metric)
      submissions = retrieve_latest_submissions
      submissions = submissions.values

      metrics_include = LinkedData::Models::Metric.goo_attrs_to_load(includes_param)
      LinkedData::Models::OntologySubmission.where.models(submissions)
                         .include(metrics: metrics_include).all

      reply submissions.select { |s| !s.metrics.nil? }.map { |s| s.metrics }
    end

  end

  # Display metrics for ontology
  get "/ontologies/:ontology/metrics" do
    check_last_modified_collection(LinkedData::Models::Metric)
    ont, sub = get_ontology_and_submission
    ont = Ontology.find(params["ontology"]).first
    error 404, "Ontology #{params['ontology']} not found" unless ont
    sub.bring(ontology: [:acronym], metrics: LinkedData::Models::Metric.goo_attrs_to_load(includes_param))
    reply sub.metrics || {}
  end

  get "/ontologies/:ontology/submissions/:submissionId/metrics" do
    check_last_modified_collection(LinkedData::Models::Metric)
    ont, sub = get_ontology_and_submission
    ont = Ontology.find(params["ontology"]).first
    error 404, "Ontology #{params['ontology']} not found" unless ont
    sub.bring(ontology: [:acronym], metrics: LinkedData::Models::Metric.goo_attrs_to_load(includes_param))
    reply sub.metrics || {}
  end

end
