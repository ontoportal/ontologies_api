class ViewsController < ApplicationController

  namespace "/ontologies/:acronym/views" do

    ##
    # Display all views of an ontology
    get do
      check_last_modified_collection(Ontology)
      ont = Ontology.find(params["acronym"]).include(views: Ontology.goo_attrs_to_load(includes_param)).first
      error 404, "You must provide a valid `acronym` to retrieve an ontology" if ont.nil?
      reply ont.views
    end

    ##
    # Display a given view
    get '/:view' do
      ont = Ontology.find(params["acronym"]).first
      error 404, "You must provide a valid ontology `acronym` to retrieve its view" if ont.nil?
      view = Ontology.find(params["view"]).first
      check_last_modified(view)
      view.bring(*Ontology.goo_attrs_to_load(includes_param))
      error 404, "You must provide a valid view `acronym` to retrieve a view" if view.nil?
      reply view
    end

    post do
      create_view
    end

    ##
    # Create view via constructed URL
    put '/:view' do
      create_view
    end

    ##
    # Update a view
    patch '/:view' do
      ont = Ontology.find(params["acronym"]).first
      error 404, "You must provide an existing ontology `acronym` to patch its view" if ont.nil?
      view = Ontology.find(params["view"]).include(Ontology.attributes(:all)).first
      error 404, "You must provide a valid view `acronym` to retrieve a view to be updated" if view.nil?

      populate_from_params(view, params)
      if view.valid?
        view.save
      else
        error 422, view.errors
      end

      halt 204
    end

    ##
    # Delete a view and all its submissions
    delete '/:view' do
      ont = Ontology.find(params["acronym"]).first
      error 404, "You must provide an existing ontology `acronym` to delete its view" if ont.nil?
      view = Ontology.find(params["view"]).first
      error 404, "You must provide a valid view `acronym` to delete a view" if view.nil?
      view.delete
      halt 204
    end

    private

    def create_view
      params ||= @params
      ont = Ontology.find(params["acronym"]).first
      error 404, "You must provide a valid ontology `acronym` to create a view on it" if ont.nil?
      view = Ontology.find(params["view"]).include(Ontology.attributes(:all)).first

      if view.nil?
        view = instance_from_params(Ontology, params)
        view.acronym = params["view"]
        view.viewOf = ont
      else
        error 409, "View already exists, to add a new submission of the view, please POST to: /ontologies/#{params["view"]}/submission. To modify the resource, use PATCH."
      end

      if view.valid?
        view.save
      else
        error 422, view.errors
      end

      reply 201, view
    end

  end
end