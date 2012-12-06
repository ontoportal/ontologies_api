class ReviewsController < ApplicationController
  namespace "/reviews" do
    # Display all reviews
    get do
    end

    # Display a single review
    get '/:review' do
    end

    # Create a new review
    post do
    end

    # Update via delete/create for an existing submission of an review
    put '/:review' do
    end

    # Update an existing submission of an review
    patch '/:review' do
    end

    # Delete a review
    delete '/:review' do
    end

  end
end