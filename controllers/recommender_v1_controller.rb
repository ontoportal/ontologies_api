class RecommenderController < ApplicationController
  namespace "/recommender_v1" do

    # Mark this route as deprecated
    get do
      reply 410, { message: "This API endpoint has been deprecated and is no longer available. Please use /recommender or refer to the API documentation for updated routes." }
    end

  end
end
