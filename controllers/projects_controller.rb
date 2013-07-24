class ProjectsController < ApplicationController

  ##
  # Ontology projects
  get "/ontologies/:acronym/projects" do
    check_last_modified_collection(LinkedData::Models::Project)
    ont = Ontology.find(params["acronym"]).include(projects: LinkedData::Models::Project.goo_attrs_to_load(includes_param)).first
    error 404, "You must provide a valid `acronym` to retrieve an ontology" if ont.nil?
    reply ont.projects
  end

  namespace "/projects" do

    MODEL = LinkedData::Models::Project
    ID_SYMBOL = :acronym
    ID_NAME = 'Project'

    # Display all projects
    get do
      check_last_modified_collection(LinkedData::Models::Project)
      reply MODEL.where.include(MODEL.goo_attrs_to_load(includes_param)).to_a
    end

    # Retrieve a single project, by unique project identifier (id)
    get '/:acronym' do
      check_last_modified_collection(LinkedData::Models::Project)
      id = params[ID_SYMBOL]
      m = MODEL.find(id).include(MODEL.goo_attrs_to_load(includes_param)).first
      if m.nil?
        error 404, "#{ID_NAME} #{id} was not found."
      end
      reply 200, m
    end

    # Create project
    post do
      create_project
    end

    # Create project via a constructed URL
    put '/:acronym' do
      create_project
    end

    # Update an existing submission of a project
    patch '/:acronym' do
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

    delete '/:acronym' do
      id = params[ID_SYMBOL]
      m = MODEL.find(id).first
      if m.nil?
        error 404, "#{ID_NAME} #{id} was not found."
      else
        m.delete
        halt 204
      end
    end

    private

    def create_project
      params ||= @params
      id = params[ID_SYMBOL] || params[ID_SYMBOL.to_s]
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

  end
end
