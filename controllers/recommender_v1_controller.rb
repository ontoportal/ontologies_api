class RecommenderController < ApplicationController
  namespace "/recommender_v1" do

    # execute an annotator query
    get do
      text = params["text"]
      raise error 400, "A text to be analyzed by the recommender must be supplied using the argument text=<text>" if text.nil? || text.strip.empty?
      acronyms = restricted_ontologies_to_acronyms(params)
      display_classes = params['display_classes'].eql?('true')  # default will be false
      recommender = Recommender::Models::NcboRecommender.new
      recommendations = recommender.recommend(text, acronyms, display_classes)
      reply 200, recommendations
    end

  end
end

