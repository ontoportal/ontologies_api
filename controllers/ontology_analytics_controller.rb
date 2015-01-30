class OntologyAnalyticsController < ApplicationController

  ONTOLOGY_ANALYTICS_REDIS_FIELD = "ontology_analytics"

  ##
  # get all ontology analytics for a given year/month combination
  namespace "/analytics" do

    get do
      redis = Redis.new(host: Annotator.settings.annotator_redis_host, port: Annotator.settings.annotator_redis_port)
      raw_analytics = redis.get(ONTOLOGY_ANALYTICS_REDIS_FIELD)
      error 404, "The ontology analytics data is currently unavailable" if raw_analytics.nil?
      analytics = Marshal.load(raw_analytics)
      year = year_param(params)
      error 400, "The year you supplied is invalid. Valid years start with 2 and contain 4 digits." if params["year"] && !year
      month = month_param(params)
      error 400, "The month you supplied is invalid. Valid months are 1-12." if params["month"] && !month

      if year && month
        analytics.values.each do |ont_analytics|
          ont_analytics.delete_if { |key, _| key != year }
          ont_analytics.each { |_, val| val.delete_if { |key, __| key != month } }
        end
      end

      reply analytics
    end

  end

  ##
  # get all analytics for a given ontology
  namespace "/ontologies/:acronym/analytics" do

    get do
      ont = Ontology.find(params["acronym"]).first
      error 404, "No ontology exists with the acronym: #{params["acronym"]}" if ont.nil?
      redis = Redis.new(host: Annotator.settings.annotator_redis_host, port: Annotator.settings.annotator_redis_port)
      raw_analytics = redis.get(ONTOLOGY_ANALYTICS_REDIS_FIELD)
      error 404, "The ontology analytics data is currently unavailable" if raw_analytics.nil?
      analytics = Marshal.load(raw_analytics)
      analytics.delete_if { |key, _| key != params["acronym"] }

      reply analytics
    end

  end

end
