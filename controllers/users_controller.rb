class UsersController < ApplicationController
  namespace "/users" do
    post "/authenticate" do
      user_id = params["user"]
      user_password = params["password"]
      user = User.find(user_id).include(User.goo_attrs_to_load + [:passwordHash]).first
      authenticated = user.authenticate(user_password) unless user.nil?
      error 401, "Username/password combination invalid" unless authenticated
      user.show_apikey = true
      reply user
    end

    # Display all users
    get do
      reply User.where.include(User.goo_attrs_to_load(includes_param)).to_a
    end

    # Display a single user
    get '/:username' do
      user = User.find(params[:username]).first
      check_last_modified(user)
      error 404, "Cannot find user with username `params['username']`" if user.nil?
      user.bring(*User.goo_attrs_to_load(includes_param))
      reply user
    end

    # Create user
    post do
      create_user
    end

    # Users get created via put because clients can assign an id (POST is only used where servers assign ids)
    put '/:username' do
      create_user
    end

    # Update an existing submission of an user
    patch '/:username' do
      user = User.find(params[:username]).include(User.attributes).first
      populate_from_params(user, params)
      if user.valid?
        user.save
      else
        error 422, user.errors
      end
      halt 204
    end

    # Delete a user
    delete '/:username' do
      User.find(params[:username]).first.delete
      halt 204
    end

    private

    def create_user
      params ||= @params
      user = User.find(params["username"]).first
      error 409, "User with username `#{params["username"]}` already exists" unless user.nil?
      user = instance_from_params(User, params)
      if user.valid?
        user.save
      else
        error 422, user.errors
      end
      reply 201, user
    end
  end
end
