class UsersController < ApplicationController
class UsersController
  namespace "/users" do
    # Display all users
    get do
    end

    # Display a single user
    get '/:user' do
    end

    # Create a new user
    post do
    end

    # Update via delete/create for an existing submission of an user
    put '/:user' do
    end

    # Update an existing submission of an user
    patch '/:user' do
    end

    # Delete a user
    delete '/:user' do
    end

  end
end