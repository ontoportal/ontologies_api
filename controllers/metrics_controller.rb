class MetricsController < ApplicationController
  namespace "/metrics" do

    # Display all metrics
    get do
      check_last_modified_collection(LinkedData::Models::Metric)
      submissions = retrieve_latest_submissions(params)
      submissions = submissions.values

      metrics_include = LinkedData::Models::Metric.goo_attrs_to_load(includes_param)
      LinkedData::Models::OntologySubmission.where.models(submissions)
                         .include(metrics: metrics_include).all

      #just a fallback or metrics that are not really built.
      to_remove = []
      submissions.each do |x|
        if x.metrics
          begin
            x.metrics.submission
          rescue
            LOGGER.error("submission with inconsistent metrics #{x.id.to_s}")
            to_remove << x
          end
        end
      end
      to_remove.each do |x|
        submissions.delete x
      end
      #end fallback

      reply submissions.select { |s| !s.metrics.nil? }.map { |s| s.metrics }
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
    ont, sub = get_ontology_and_submission
    error 404, "Ontology #{params['ontology']} not found" unless ont
    sub.bring(ontology: [:acronym], metrics: LinkedData::Models::Metric.goo_attrs_to_load(includes_param))
    reply sub.metrics || {}
    # ont_str = ""
    # LinkedData::Models::Ontology.all.each  do |ont|
    #   begin
    #     sub = ont.latest_submission(status: :rdf)
    #     sub.bring(ontology: [:acronym], metrics: LinkedData::Models::Metric.goo_attrs_to_load(includes_param))
    #     if !sub.metrics
    #       ont_str << "#{ont.acronym},"
    #       puts ont_str
    #     end
    #   rescue Exception => e
    #     puts "#{ont.acronym}: #{e.message}"
    #   end
    # end
    # puts ont_str
    # reply {}
  end

  get "/ontologies/:ontology/submissions/:ontology_submission_id/metrics" do
    check_last_modified_collection(LinkedData::Models::Metric)
    ont, sub = get_ontology_and_submission
    error 404, "Ontology #{params['ontology']} not found" unless ont
    sub.bring(ontology: [:acronym], metrics: LinkedData::Models::Metric.goo_attrs_to_load(includes_param))
    reply sub.metrics || {}
  end


end
