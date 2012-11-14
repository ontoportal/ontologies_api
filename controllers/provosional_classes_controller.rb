class ProvisionalClassController < ApplicationController
  namespace "/provisional_classes" do
    # Default content type (this will need to support all of our content types eventually)
    before { content_type :json }

    # Display all provisional_classes
    get do
    end

    # Display a single provisional_class
    get '/:provisional_class' do
    end

    # Create a new provisional_class
    post do
    end

    # Update via delete/create for an existing submission of an provisional_class
    put '/:provisional_class' do
    end

    # Update an existing submission of an provisional_class
    patch '/:provisional_class' do
    end

    # Delete a provisional_class
    delete '/:provisional_class' do
    end
  end
end