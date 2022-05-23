class SlicesController < ApplicationController
  namespace "/slices" do
    get do
      expires 3600, :public
      check_last_modified_collection(LinkedData::Models::Slice)
      includes = LinkedData::Models::Slice.goo_attrs_to_load(includes_param)
      reply LinkedData::Models::Slice.where.include(includes).all
    end

    get '/:slice_id' do
      slice = LinkedData::Models::Slice.where(acronym: params["slice_id"]).first
      error 404, "Slice #{params['slice_id']} not found" if slice.nil?
      check_last_modified(slice)
      slice.bring(*LinkedData::Models::Slice.goo_attrs_to_load(includes_param))
      reply slice
    end
  end
end