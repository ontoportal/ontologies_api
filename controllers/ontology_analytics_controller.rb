require 'csv'

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
        # sort results by the highest traffic values
        analytics = Hash[analytics.sort_by {|k, v| v[year][month]}.reverse]
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

      if params["format"].to_s.downcase.eql?("csv")
        tf = Tempfile.new("analytics-#{params['acronym']}")
        csv = CSV.new(tf, headers: true, return_headers: true, write_headers: true)
        csv << [:month, :visits]
        years = analytics[params["acronym"]].keys.sort
        now = Time.now
        years.each do |year|
          months = analytics[params["acronym"]][year].keys.sort
          months.each do |month|
            next if now.year == year && now.month <= month || (year == 2013 && month < 10) # we don't have good data going back past Oct 2013
            visits = analytics[params["acronym"]][year][month]
            month = DateTime.parse("#{year}/#{month}").strftime("%b %Y")
            csv << [month, visits]
          end
        end
        csv.close
        content_type "text/csv"
        send_file tf.path, filename: "analytics-#{params['acronym']}.csv"
      else
        reply analytics
      end
    end

  end

end
