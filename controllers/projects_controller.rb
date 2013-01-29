class ProjectsController
  namespace "/projects" do

    # Display all projects
    get do
      reply LinkedData::Models::Project.all
    end

    # Retrieve a single project, by unique project identifier (name)
    get '/:project' do
      name = params[:project]
      p = LinkedData::Models::Project.where(:name => name)
      if p.length == 1
        reply p[0]
      else
        if p.length == 0
          error 404, "Project #{name} was not found."
        else
          error 500, "Project retrieval error; projects found = #{p}"
        end
      end
    end

    # Projects get created via put because clients can assign an id (POST is only used where servers assign ids)
    put '/:project' do
      # TODO: Figure out how to get additional model attribute values into params
      p = instance_from_params(LinkedData::Models::Project, params)
      if p.valid?
        p.save
        reply 201, p
      else
        error 400, p.errors
      end
    end

    # Update an existing submission of a project
    patch '/:project' do
      p = LinkedData::Models::Project.find(params[:project])
      p = populate_from_params(p, params)
      if p.valid?
        p.save
        halt 204
      else
        error 404, p.errors
      end
    end

    # Delete a project
    delete '/:project' do
      p = LinkedData::Models::Project.find(params[:project])
      if p.nil?
        halt 404
      else
        p.delete
        halt 204
      end
    end

  end
end
