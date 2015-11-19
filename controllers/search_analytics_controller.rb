require 'csv'

class SearchAnalyticsController < ApplicationController

  ##
  # get all ontology analytics for a given year/month combination
  namespace "/:concept/ccv" do

    get do
      reply ["test", "test1", "test2"]
    end

  end

end
