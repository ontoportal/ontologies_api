class InstancesController < ApplicationController

  # Display individuals for a class
  get '/ontologies/:ontology/classes/:cls/instances' do

    ont, sub = get_ontology_and_submission
    check_last_modified_segment(LinkedData::Models::Instance, [ont.acronym])
    cls = get_class(sub)
    error 404 if cls.nil?

    page, size = page_params
    attributes = get_attributes_to_include(includes_param)

    page_data = LinkedData::Models::Instance.where(filter_classes_by(cls.id))
                                            .filter(label_regex_filter).in(sub)
                                            .include(attributes).page(page,size).all

    bring_unmapped_if_needed  includes_param, page_data , sub

    reply page_data
  end

  namespace "/ontologies/:ontology/instances" do
    # Display individuals for an ontology
    get do
      ont, sub = get_ontology_and_submission
      check_last_modified_segment(LinkedData::Models::Instance, [ont.acronym])

      page, size = page_params
      attributes = get_attributes_to_include(includes_param)

      page_data = LinkedData::Models::Instance.where.filter(label_regex_filter)
                                              .in(sub)
                                              .include(attributes)
                                              .page(page,size).all

      bring_unmapped_if_needed  includes_param, page_data , sub
      reply page_data
    end

    get '/:inst' do
      ont, sub = get_ontology_and_submission
      check_last_modified_segment(LinkedData::Models::Instance, [ont.acronym])

      attributes = get_attributes_to_include(includes_param)

      page_data = LinkedData::Models::Instance.find(@params["inst"]).include(attributes).in(sub).first


      bring_unmapped_if_needed  includes_param, [page_data] , sub
      reply page_data
    end
  end


end


