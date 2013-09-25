class RecommenderController < ApplicationController
  namespace "/recommender" do

    # execute an annotator query
    get do
      text = params["text"]
      raise error 400, "A text to be analyzed by the recommender must be supplied using the argument text=<text>" if text.nil? || text.strip.empty?
      acronyms = restricted_ontologies_to_acronyms(params)
      recommender = Recommender::Models::NcboRecommender.new
      recommendations = recommender.recommend(text, acronyms)
      reply 200, recommendations
    end

  end
end

