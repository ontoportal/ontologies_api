class MappingsController < ApplicationController
  # Get mappings for a class
  get '/ontologies/:ontology/classes/:cls/mappings' do
    source = params[:source]
    target = params[:target]
  end

  # Get mappings for an ontology
  get '/ontologies/:ontology/mappings' do
    source = params[:source_ontology]
    target = params[:target_ontology]
  end

  namespace "/mappings" do
    # Display all mappings
    get do
    end

    # Display a single mapping
    get '/:mapping' do
    end

    # Create a new mapping
    post do
    end

    # Update via delete/create for an existing submission of an mapping
    put '/:mapping' do
    end

    # Update an existing submission of an mapping
    patch '/:mapping' do
    end

    # Delete a mapping
    delete '/:mapping' do
    end
  end

  namespace "/mappings/statistics" do
    # List recent mappings
    get '/recent' do
    end

    # Statistics for an ontology
    get '/ontologies/:ontology' do
    end

    # Classes with lots of mappings
    get '/ontologies/:ontology/popular_classes' do
    end

    # Users with lots of mappings
    get '/ontologies/:ontology/users' do
    end
  end
end
