class ProjectsController
  namespace "/projects" do
    # Display all projects
    get do
      p = LinkedData::Models::Project.all
      reply p
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
          error 505, "Project retrieval error, projects found = #{p}"
        end
      end
    end

    # Create a project with the given acronym
    put '/:project' do
      p = instance_from_params(LinkedData::Models::Project, params)
      if p.valid?
        p.load
        reply p
      else
        error 505, "#{p.errors}"
      end
    end

    # Update an existing submission of an project
    patch '/:project' do
      p = LinkedData::Models::Project.find(params[:project])
      if p.valid?
        p.load
        p = populate_from_params(p, params)
        reply p
      else
        halt 404
      end
    end

    # Delete a project
    delete '/:project' do
      p = LinkedData::Models::Project.find(params[:project])
      if p.valid?
        p.delete
        reply 201
      else
        halt 505
      end
    end

  end
end