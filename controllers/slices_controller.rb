class SlicesController < ApplicationController
  namespace "/slices" do
    get do
      expires 3600, :public
      check_last_modified_collection(LinkedData::Models::Slice)
      includes = LinkedData::Models::Slice.goo_attrs_to_load(includes_param)
      reply LinkedData::Models::Slice.where.include(includes).all
    end

    ##
    # Create a new slice
    post do
      create_slice
    end

    # Delete a slice
    delete '/:slice' do
      LinkedData::Models::Slice.find(params[:slice]).first.delete
      halt 204
    end

    # Update an existing slice
    patch '/:slice' do
      slice = LinkedData::Models::Slice.find(params[:slice]).include(LinkedData::Models::Slice.attributes(:all)).first
      populate_from_params(slice, params)
      if slice.valid?
        slice.save
      else
        error 422, slice.errors
      end
      halt 204
    end


    private

    def create_slice
      params ||= @params
      ontologies = []

      params["ontologies"].each do |ont|
        ontologies.push(LinkedData::Models::Ontology.find(ont).first)
      end

      slice = LinkedData::Models::Slice.new({
        acronym: params["acronym"],
        name: params["name"],
        description: params["description"],
        ontologies: ontologies
       })

      if slice.valid?
        slice.save
      else
        error 400, slice.errors
      end
      reply 201, slice
    end

  end

end