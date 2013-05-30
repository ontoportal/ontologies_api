class ProjectsController < ApplicationController

  ##
  # Ontology projects
  get "/ontologies/:acronym/projects" do
    ont = Ontology.find(params["acronym"]).include(:projects).first
    error 404, "You must provide a valid `acronym` to retrieve an ontology" if ont.nil?
    reply ont.projects
  end

  namespace "/projects" do

    MODEL = LinkedData::Models::Project
    ID_SYMBOL = :project
    ID_NAME = 'Project'

    # Display all projects
    get do
      reply MODEL.where.include(MODEL.goo_attrs_to_load(includes_param)).to_a
    end

    # Retrieve a single project, by unique project identifier (id)
    get '/:project' do
      id = params[ID_SYMBOL]
      m = MODEL.find(id).include(MODEL.goo_attrs_to_load(includes_param)).first
      if m.nil?
        error 404, "#{ID_NAME} #{id} was not found."
      end
      reply 200, m
    end

    # Projects get created via put because clients can assign an id (POST is only used where servers assign ids)
    put '/:project' do
      id = params[ID_SYMBOL]
      m = MODEL.find(id).first
      unless m.nil?
        error 409, "#{ID_NAME} #{id} already exists. Submit updates using HTTP PATCH instead of PUT."
      end
      m = instance_from_params(MODEL, params)
      if m.valid?
        m.save
        reply 201, m
      else
        error 422, m.errors
      end
    end

    # Update an existing submission of a project
    patch '/:project' do
      id = params[ID_SYMBOL]
      m = MODEL.find(id).include(MODEL.attributes).first
      if m.nil?
        error 404, "#{ID_NAME} #{id} was not found, cannot PATCH."
      end
      m = populate_from_params(m, params)
      if m.valid?
        m.save
        halt 204
      else
        error 422, m.errors
      end
    end

    delete '/:project' do
      id = params[ID_SYMBOL]
      m = MODEL.find(id).first
      if m.nil?
        error 404, "#{ID_NAME} #{id} was not found."
      else
        m.delete
        halt 204
      end
    end

  end
end
