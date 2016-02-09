class ProvisionalClassesController < ApplicationController
  ##
  # Ontology provisional classes
  get "/ontologies/:ontology/provisional_classes" do
    check_last_modified_collection(LinkedData::Models::ProvisionalClass)
    ont = Ontology.find(params["ontology"]).include(provisionalClasses: LinkedData::Models::ProvisionalClass.goo_attrs_to_load(includes_param)).first
    error 404, "You must provide a valid id to retrieve provisional classes for an ontology" if ont.nil?
    reply ont.provisionalClasses
  end

  # Display provisional classes for a particular user
  get "/users/:user/provisional_classes" do
    check_last_modified_collection(LinkedData::Models::ProvisionalClass)
    user = User.find(params["user"]).include(provisionalClasses: LinkedData::Models::ProvisionalClass.goo_attrs_to_load(includes_param)).first
    error 404, "User #{user} not found. Please provide a valid user to retrieve provisonal classes." if user.nil?
    reply user.provisionalClasses
  end

  namespace "/provisional_classes" do
    # Display all provisional_classes
    get do
      check_last_modified_collection(LinkedData::Models::ProvisionalClass)
      incl_param = includes_param
      incl_param << :created if (!incl_param.empty? && !incl_param.include?(:created))
      prov_classes = ProvisionalClass.where.include(ProvisionalClass.goo_attrs_to_load(incl_param)).to_a
      reply prov_classes.sort {|a,b| b.created <=> a.created }  # most recent first
    end

    # Display a single provisional_class
    get '/:provisional_class_id' do
      check_last_modified_collection(LinkedData::Models::ProvisionalClass)
      id = uri_as_needed(params["provisional_class_id"])
      pc = ProvisionalClass.find(id).include(ProvisionalClass.goo_attrs_to_load(includes_param)).first
      error 404, "Provisional class #{id} not found" if pc.nil?
      reply 200, pc
    end

    # Create a new provisional_class
    post do
      relations = params.delete("relations")
      pc = instance_from_params(ProvisionalClass, params)

      if pc.valid?
        pc.save
        rels = save_provisional_class_relations(relations, pc)

        # if there were any errors creating relations, fail the entire transaction
        unless rels["errors"].empty?
          pc.delete
          error 400, rels["errors"]
        end
      else
        error 400, pc.errors
      end
      reply 201, pc
    end

    # Update an existing submission of a provisional_class
    # Delete all existing relations and save new ones from the request
    patch '/:provisional_class_id' do
      id = uri_as_needed(params["provisional_class_id"])
      pc = ProvisionalClass.find(id).include(ProvisionalClass.attributes).first

      if pc.nil?
        error 400, "Provisional class with id #{id} does not exist"
      else
        relations_param = params.delete("relations")
        pc.bring_remaining
        populate_from_params(pc, params)

        if pc.valid?
          pc.bring(:relations)
          old_rel = pc.relations.dup

          # if there were any errors creating new relations, fail the entire transaction
          new_rel = save_provisional_class_relations(relations_param, pc)

          if new_rel["errors"].empty?
            pc.save
            old_rel.each { |rel| rel.delete }
          else
            error 400, new_rel["errors"]
          end
        else
          error 400, pc.errors
        end
      end
      halt 204
    end

    # Delete a provisional_class and all provisional relations
    delete '/:provisional_class_id' do
      id = uri_as_needed(params["provisional_class_id"])
      pc = ProvisionalClass.find(id).first

      if pc.nil?
        error 400, "Provisional class #{id} does not exist."
      end
      pc.bring_remaining
      pc.bring(:relations)
      pc.relations.each {|rel| rel.delete}

      pc.delete
      halt 204
    end
  end
end
