class OntologiesController < ApplicationController
  namespace "/ontologies" do

    ##
    # Display all ontologies
    get do
      onts = Ontology.all(load_attrs: Ontology.goo_attrs_to_load(includes_options))
      reply onts
    end

    ##
    # Display the most recent submission of the ontology
    get '/:acronym' do
      ont = Ontology.find(params["acronym"])
      error 404, "You must provide a valid `acronym` to retrieve an ontology" if ont.nil?
      reply ont
    end

    ##
    # Ontology groups
    get "/:acronym/groups" do
      ont = Ontology.find(params["acronym"], load_attrs: {group: Group.goo_attrs_to_load})
      error 404, "You must provide a valid `acronym` to retrieve an ontology" if ont.nil?
      reply ont.group
    end

    ##
    # Ontology categories
    get "/:acronym/categories" do
      ont = Ontology.find(params["acronym"], load_attrs: {hasDomain: Category.goo_attrs_to_load})
      error 404, "You must provide a valid `acronym` to retrieve an ontology" if ont.nil?
      reply ont.hasDomain
    end

    ##
    # Ontology categories
    get "/:acronym/projects" do
      ont = Ontology.find(params["acronym"])
      error 404, "You must provide a valid `acronym` to retrieve an ontology" if ont.nil?
      reply ont.projects
    end

    ##
    # Ontologies get created via put because clients can assign an id (POST is only used where servers assign ids)
    put '/:acronym' do
      ont = Ontology.find(params["acronym"])
      if ont.nil?
        ont = instance_from_params(Ontology, params)
      else
        error 409, "Ontology already exists, to add a new submission, please POST to: /ontologies/#{params["acronym"]}/submission. To modify the resource, use PATCH."
      end

      if ont.valid?
        ont.save
      else
        error 422, ont.errors
      end

      reply 201, ont
    end

    ##
    # Update an ontology
    patch '/:acronym' do
      ont = Ontology.find(params["acronym"])
      error 422, "You must provide an existing `acronym` to patch" if ont.nil?

      populate_from_params(ont, params)
      if ont.valid?
        ont.save
      else
        error 422, ont.errors
      end

      halt 204
    end

    ##
    # Delete an ontology and all its versions
    delete '/:acronym' do
      ont = Ontology.find(params["acronym"])
      error 422, "You must provide an existing `acronym` to delete" if ont.nil?
      ont.delete
      halt 204
    end

    ##
    # Download an ontology
    get '/:acronym/download' do
      error 500, "Not implemented"
    end

    ##
    # Properties for given ontology
    get '/:acronym/properties' do
      error 500, "Not implemented"
    end

  end
end
