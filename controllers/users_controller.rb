class UsersController
  namespace "/users" do
    # Display all users
    get do
      reply User.all(load_attrs: User.goo_attrs_to_load)
    end

    # Display a single user
    get '/:username' do
      reply User.find(params[:username])
    end

    # Users get created via put because clients can assign an id (POST is only used where servers assign ids)
    put '/:username' do
      user = User.find(params["username"])
      error 409, "User with username `#{params["username"]}` already exists" unless user.nil?
      user = instance_from_params(User, params)
      if user.valid?
        user.save
      else
        error 422, user.errors
      end
      reply 201, user
    end

    # Update an existing submission of an user
    patch '/:username' do
      user = User.find(params[:username])
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
      User.find(params[:username]).delete
      halt 204
    end

  end
end
