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
      acronym = params["group"]
      group = Group.find(acronym)
      if group.nil?
        group = instance_from_params(Group, params)
      else
        error 400, "Group exists, please use HTTP PATCH to update"
      end

      if group.valid?
        group.save
      else
        error 400, group.errors
      end
      reply 201, group
    end

    # Update an existing submission of an group
    patch '/:group' do
      acronym = params["group"]
      group = Group.find(acronym)
      if group.nil?
        error 400, "Group does not exist, please create using HTTP PUT before modifying"
      else
        populate_from_params(group, params)
        if group.valid?
          group.save
        else
          error 400, group.errors
        end
      end
      halt 204
    end

    # Delete a group
    delete '/:group' do
      g = Group.find(params["group"])
      g.load unless g.loaded?
      g.delete
      halt 204
    end
  end
end