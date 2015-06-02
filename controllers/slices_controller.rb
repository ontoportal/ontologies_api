class SlicesController < ApplicationController
  namespace "/slices" do
    get do
      expires 3600, :public
      check_last_modified_collection(LinkedData::Models::Slice)
      includes = LinkedData::Models::Slice.goo_attrs_to_load(includes_param)
      reply LinkedData::Models::Slice.where.include(includes).all
    end
  end
end