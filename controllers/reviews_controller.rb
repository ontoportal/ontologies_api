class ReviewsController
  namespace "/reviews" do

    MODEL = LinkedData::Models::Review
    ID_SYMBOL = :review
    ID_NAME = 'Review'

    # Display all reviews
    get do
      reply MODEL.all
    end

    # Display a single review
    get '/:review' do
      id = params[ID_SYMBOL]
      m = MODEL.find(id)
      if m.nil?
        error 404, "#{ID_NAME} #{id} was not found."
      end
      reply 200, m
    end

    # Create a new review
    put '/:review' do
      id = params[ID_SYMBOL]
      m = MODEL.find(id)
      if not m.nil?
        error 409, "#{ID_NAME} #{id} already exists. Submit updates using HTTP PATCH instead of PUT."
      end
      m = instance_from_params(MODEL, params)
      if m.valid?
        m.save
        reply 201, m
      else
        error 422, m.errors
      end
    end

    # Update an existing submission of a review
    patch '/:review' do
      id = params[ID_SYMBOL]
      m = MODEL.find(id)
      if m.nil?
        error 404, "#{ID_NAME} #{id} was not found. Submit new items using HTTP PUT instead of PATCH."
      end
      m = populate_from_params(m, params)
      if m.valid?
        m.save
        halt 204
      else
        error 422, m.errors
      end
    end

    # Delete a review
    delete '/:review' do
      id = params[ID_SYMBOL]
      m = MODEL.find(id)
      if m.nil?
        error 404, "#{ID_NAME} #{id} was not found."
      else
        m.delete
        halt 204
      end
    end

  end
end
