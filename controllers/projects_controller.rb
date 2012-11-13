class ProjectsController < ApplicationController
  namespace "/projects" do
    # Default content type (this will need to support all of our content types eventually)
    before { content_type :json }

    # Display all projects
    get do
    end

    # Display a single project
    get '/:project' do
    end

    # Create a new project
    post do
    end

    # Update via delete/create for an existing submission of an project
    put '/:project' do
    end

    # Update an existing submission of an project
    patch '/:project' do
    end

    # Delete a project
    delete '/:project' do
    end

  end
end