class CategoriesController < ApplicationController
  namespace "/categories" do
    # Default content type (this will need to support all of our content types eventually)
    before { content_type :json }

    # Display all categories
    get do
    end

    # Display a single category
    get '/:category' do
    end

    # Create a new category
    post do
    end

    # Update via delete/create for an existing submission of an category
    put '/:category' do
    end

    # Update an existing submission of an category
    patch '/:category' do
    end

    # Delete a category
    delete '/:category' do
    end

  end
end