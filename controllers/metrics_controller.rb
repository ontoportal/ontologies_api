class MetricsController < ApplicationController
  namespace "/metrics" do

    # Display all metrics
    get do
      check_last_modified_collection(LinkedData::Models::Metric)
      latest_metrics = LinkedData::Models::Metric.where.include(LinkedData::Models::Metric.goo_attrs_to_load(includes_param)).all
                    .group_by { |x| x.id.split('/')[-4] }
                    .transform_values { |metrics| metrics.max_by { |x| x.id.split('/')[-2].to_i } }
      reply latest_metrics.values
    end

    #
    # Note: useful submission status states:
    #LinkedData::Models::SubmissionStatus::VALUES.sort
    #=> ["ANNOTATOR",
    #    "ARCHIVED",
    #    "ERROR_ANNOTATOR",
    #    "ERROR_ARCHIVED",
    #    "ERROR_INDEXED",
    #    "ERROR_METRICS",
    #    "ERROR_OBSOLETE",
    #    "ERROR_RDF",
    #    "ERROR_RDF_LABELS",
    #    "ERROR_UPLOADED",
    #    "INDEXED",
    #    "METRICS",
    #    "OBSOLETE",
    #    "RDF",
    #    "RDF_LABELS",
    #    "UPLOADED"]

    get '/missing' do
      missing = Set.new()
      onts = LinkedData::Models::Ontology.all
      onts.each do |ont|
        ont.bring(:summaryOnly)
        next if ont.summaryOnly
        # Get the latest submission, but ensure the processing status
        # doesn't require anything more than RDF parsing.
        sub = ont.latest_submission(:status => 'RDF')
        if sub.nil?
          missing.add(ont)
        else
          status = sub.submissionStatus.map {|s| s.id.to_s.split('/').last }
          if status.include? 'ERROR_METRICS'
            missing.add(ont)
          else
            if status.include? 'METRICS'
              sub.bring(:metrics)
              missing.add(ont) if sub.metrics.nil?
            else
              missing.add(ont)
            end
          end
        end
      end
      reply missing.to_a
    end

  end  # namespace /metrics

  # Display metrics for ontology
  get "/ontologies/:ontology/metrics" do
    check_last_modified_collection(LinkedData::Models::Metric)
    ont = Ontology.find(params['ontology']).first
    error 404, "Ontology #{params['ontology']} not found" unless ont
    ontology_metrics = LinkedData::Models::Metric
                      .where(submission: {ontology: [acronym: params['ontology']]})
                      .order_by(submission: {submissionId: :desc})
                      .include(LinkedData::Models::Metric.goo_attrs_to_load(includes_param)).first
    reply ontology_metrics || {}
  end

  get "/ontologies/:ontology/submissions/:ontology_submission_id/metrics" do
    check_last_modified_collection(LinkedData::Models::Metric)
    ont = Ontology.find(params['ontology']).first
    error 404, "Ontology #{params['ontology']} not found" unless ont
    ontology_submission_metrics = LinkedData::Models::Metric
                      .where(submission: { submissionId: params['ontology_submission_id'].to_i, ontology: [acronym: params['ontology']] })
                      .include(LinkedData::Models::Metric.goo_attrs_to_load(includes_param)).first
    reply ontology_submission_metrics || {}
  end


end
