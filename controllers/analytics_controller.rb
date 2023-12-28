require 'csv'

class AnalyticsController < ApplicationController

  ##
  # get all ontology analytics for a given year/month combination
  # TODO use a namespace analytics after migration the old OntologyAnalyticsController
  namespace "/data/analytics" do

    get '/ontologies' do
      expires 86400, :public
      year = year_param(params)
      error 400, "The year you supplied is invalid. Valid years start with 2 and contain 4 digits." if params["year"] && !year
      month = month_param(params)
      error 400, "The month you supplied is invalid. Valid months are 1-12." if params["month"] && !month
      acronyms = restricted_ontologies_to_acronyms(params)
      analytics = Ontology.analytics(year, month, acronyms)

      reply analytics
    end


    get '/users' do
      expires 86400, :public
      year = year_param(params)
      error 400, "The year you supplied is invalid. Valid years start with 2 and contain 4 digits." if params["year"] && !year
      month = month_param(params)
      error 400, "The month you supplied is invalid. Valid months are 1-12." if params["month"] && !month
      analytics = User.analytics(year, month)
      reply analytics['all_users']
    end

    get '/page_visits' do
      expires 86400, :public
      year = year_param(params)
      error 400, "The year you supplied is invalid. Valid years start with 2 and contain 4 digits." if params["year"] && !year
      month = month_param(params)
      error 400, "The month you supplied is invalid. Valid months are 1-12." if params["month"] && !month
      analytics = User.page_visits_analytics
      reply analytics['all_pages']
    end

  end

end
