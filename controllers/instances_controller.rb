class InstancesController < ApplicationController

  # Display individuals for a class
  get '/ontologies/:ontology/classes/:cls/instances' do
    ont, sub = get_ontology_and_submission
    check_last_modified_segment(LinkedData::Models::Class, [ont.acronym])
    cls = get_class(sub)
    error 404 if cls.nil?
    reply LinkedData::InstanceLoader.get_instances_by_class(sub.id, cls.id)
  end

  namespace "/ontologies/:ontology/instances" do

    # Display individuals for an ontology
    get do
      ont, sub = get_ontology_and_submission
      check_last_modified_segment(LinkedData::Models::Instance, [ont.acronym])
      page, size = page_params
      reply LinkedData::InstanceLoader.get_instances_by_ontology(sub.id, page, size)
    end

  end
end


