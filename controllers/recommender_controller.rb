class RecommenderController < ApplicationController
  namespace "/recommender" do

    # Executes a Recommender query.
    get do
      input = params["input"]
      raise error 400, "A text or keywords to be analyzed by the recommender must be supplied using the argument input=<input>" if input.nil? || input.strip.empty?
      # acronyms = restricted_ontologies_to_acronyms(params)
      # display_classes = params['display_classes'].eql?('true')  # default will be false
      # recommender = Recommender::Models::NcboRecommender.new
      # recommendations = recommender.recommend(text, acronyms, display_classes)
      # reply 200, recommendations

      recommender = Recommender2::NcboRecommender.new

      ontologies = []
      input = 'melanoma, white blood cell, melanoma,     arm, cavity of stomach'
      input_type = 2
      delimiter = ','
      reply 200, recommender.recommend(input, input_type, delimiter, ontologies)

    end

  end
end

