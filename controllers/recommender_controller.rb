class RecommenderController < ApplicationController
  namespace "/recommender" do

    # execute an annotator query
    get do
      text = params["text"]
      raise error 400, "A text to be analyzed by the recommender must be supplied using the argument text=<text>" if text.nil? || text.strip.empty?
      ontologies = ontologies_param_to_acronyms
      recommender = Recommender::Models::NcboRecommender.new
      recommendations = recommender.recommend(text, ontologies)
      reply 200, recommendations
    end

    private

    def get_page_params(text, args={})
      return args
    end
  end
end

