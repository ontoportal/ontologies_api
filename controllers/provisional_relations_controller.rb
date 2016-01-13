class ProvisionalRelationsController < ApplicationController

  namespace "/provisional_relations" do
    # Display all provisional_relations
    get do
      check_last_modified_collection(LinkedData::Models::ProvisionalRelation)
      prov_rel = ProvisionalRelation.where.include(ProvisionalRelation.goo_attrs_to_load(includes_param)).to_a
      reply prov_rel.sort {|a,b| b.created <=> a.created }  # most recent first
    end

    # Display a single provisional_relation
    get '/:provisional_relation_id' do
      check_last_modified_collection(LinkedData::Models::ProvisionalRelation)
      id = uri_as_needed(params["provisional_relation_id"])
      rel = ProvisionalRelation.find(id).include(ProvisionalRelation.goo_attrs_to_load(includes_param)).first
      error 404, "Provisional relation #{id} not found" if rel.nil?
      reply 200, rel
    end

    # Create a new provisional_relation
    post do
      rels = save_provisional_class_relations(params)
      error 400, rels["errors"] unless rels["errors"].empty?
      reply 201, rels["objects"][0]
    end







# need delete that takes source, target and relationType instead of just ID





    # Delete a provisional_relation
    delete '/:provisional_relation_id' do
      id = uri_as_needed(params["provisional_relation_id"])
      rel = ProvisionalRelation.find(id).first

      if rel.nil?
        error 400, "Provisional relation #{id} does not exist."
      end

      rel.delete
      halt 204
    end
  end
end
