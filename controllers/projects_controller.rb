class ProjectsController
  namespace "/projects" do

    # Display all projects
    get do
      reply LinkedData::Models::Project.all
    end

    # Retrieve a single project, by unique project identifier (acronym)
    get '/:project' do
      acronym = params[:project]
      p = LinkedData::Models::Project.find(acronym)
      if p.nil?
        error 404, "Project #{acronym} was not found."
      end
      reply 200, p
    end

    # Projects get created via put because clients can assign an id (POST is only used where servers assign ids)
    put '/:project' do
      acronym = params[:project]
      p = LinkedData::Models::Project.find(acronym)
      if not p.nil?
        error 409, "Project #{acronym} already exists. Submit project updates using HTTP PATCH instead of PUT."
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
      acronym = params[:project]
      p = LinkedData::Models::Project.find(acronym)
      if p.nil?
        error 404, "Project #{acronym} was not found. Submit new projects using HTTP PUT instead of PATCH."
      end
      p = populate_from_params(p, params)
      if p.valid?
        p.save
        halt 204
      else
        error 422, p.errors
      end
    end

    # Delete a project
    delete '/:project' do
      acronym = params[:project]
      p = LinkedData::Models::Project.find(acronym)
      if p.nil?
        error 404, "Project #{acronym} was not found."
      else
        p.delete
        halt 204
      end
    end

  end
end
