class ProjectsController
  namespace "/projects" do

    # Display all projects
    get do
      reply LinkedData::Models::Project.all
    end

    # Retrieve a single project, by unique project identifier (name)
    get '/:project' do
      name = params[:project]
      p = LinkedData::Models::Project.find(name)
      if p.nil?
        error 404, "Project #{name} was not found."
      end
      if p.valid?
        reply 200, p
      else
        error 500, "Project retrieval error, #{p.errors}"
      end
    end

    # Projects get created via put because clients can assign an id (POST is only used where servers assign ids)
    put '/:project' do
      name = params[:project]
      p = LinkedData::Models::Project.find(name)
      if not p.nil?
        error 409, "Project #{name} already exists. Submit project updates using HTTP PATCH instead of PUT."
      end
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
      name = params[:project]
      p = LinkedData::Models::Project.find(name)
      if p.nil?
        error 404, "Project #{name} was not found. Submit new projects using HTTP PUT instead of PATCH."
      end
      p = populate_from_params(p, params)
      if p.valid?
        p.save
        halt 204
      else
        error 500, p.errors
      end
    end

    # Delete a project
    delete '/:project' do
      name = params[:project]
      p = LinkedData::Models::Project.find(name)
      if p.nil?
        error 404, "Project #{name} was not found."
      else
        p.delete
        halt 204
      end
    end

  end
end
