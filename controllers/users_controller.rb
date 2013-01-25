class UsersController
  namespace "/users" do
    # Display all users
    get do
      reply User.all
    end

    # Display a single user
    get '/:username' do
      reply User.find(params[:username])
    end

    # Users get created via put because clients can assign an id (POST is only used where servers assign ids)
    put '/:username' do
      user = instance_from_params(User, params)
      if user.valid?
        user.save
      else
        error 400, user.errors
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
        error 400, user.errors
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