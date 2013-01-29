class GroupsController
  namespace "/groups" do
    # Display all groups
    get do
      groups = Group.all
      reply groups
    end

    # Display a single group
    get '/:group' do
      acronym = params["group"]
      g = Group.find(acronym)

      error 404, "Group #{acronym} not found" if g.nil?
      reply 200, g
    end

    # Create a group with the given acronym
    put '/:group' do
    end

    # Update an existing submission of an group
    patch '/:group' do
    end

    # Delete a group
    delete '/:group' do
    end

  end
end