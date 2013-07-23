class ReviewsController < ApplicationController

  MODEL = LinkedData::Models::Review

  namespace "/ontologies/:acronym/reviews" do
    # Return an array of reviews for an ontology acronym.
    get do
      check_last_modified_collection(MODEL)
      ont = LinkedData::Models::Ontology.find(params["acronym"]).include(reviews: MODEL.goo_attrs_to_load(includes_param)).first
      reply ont.reviews
    end
  end

  namespace "/reviews" do
    # Return an array of all reviews.
    get do
      check_last_modified_collection(MODEL)
      reply MODEL.where.include(MODEL.goo_attrs_to_load(includes_param)).to_a
    end

    get '/:review_id' do
      review = MODEL.find(params["review_id"]).first
      error 404, "Review #{params['review_id']} not found" if review.nil?
      check_last_modified(review)
      review.bring(*MODEL.goo_attrs_to_load(includes_param))
      reply review
    end

    # Create a new review
    post do
      create_review
    end

    # Update an existing review
    patch '/:review_id' do
      review = MODEL.find(params["review_id"]).first
      error 404, "Review #{params['review_id']} not found" if review.nil?
      populate_from_params(review, params)

      if review.valid?
        review.save
        halt 204
      else
        error 422, review.errors
      end
    end

    delete "/:review_id" do
      review = MODEL.find(params["review_id"]).first
      error 404, "Review #{params['review_id']} not found" if review.nil?
      review.delete
      halt 204
    end

    private

    def create_review
      params ||= @params
      review = MODEL.find(params["review_id"]).first if params["review_id"]
      error 409, "Reviews already exist for ontology: #{params[:acronym]}, by user: #{params[:username]}. Update using PATCH instead of PUT." unless review.nil?

      review = instance_from_params(MODEL, params)
      if review.valid?
        review.save
        reply 201, review
      else
        error 422, review.errors
      end
    end
  end
end

