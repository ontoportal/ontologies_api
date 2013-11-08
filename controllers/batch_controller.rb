class BatchController < ApplicationController
  namespace "/batch" do
    post do
      fix_batch_params_for_request()
      resource_type = "http://www.w3.org/2002/07/owl#Class"
      unless params.key?(resource_type)
        error 422, "Batch endpoint only support calls to owl:Class resources"
      end
      batch_params = params[resource_type]
      incl = batch_params["include"].split(",").map {|e| e.to_sym}
      collection = batch_params["collection"]
      error 422, "Call should contain 'include' parameters" if incl.nil?
      error 422, "Call should contain 'collection' parameter" if collection.nil? || collection.length == 0
      goo_include = LinkedData::Models::Class.goo_attrs_to_load(incl)
      class_id_by_ontology = {}
      collection.each do |class_input|
        unless class_input.instance_of?(Hash)
          error 422, "The collection param needs to be { 'class' : CLS_ID, 'ontology' : ont_id }"
        end
        unless class_input.include?("ontology") and class_input.include?("class")
          error 422, "The collection param needs to be { 'class' : CLS_ID, 'ontology' : ont_id }"
        end
        unless class_id_by_ontology.include? class_input["ontology"]
          class_id_by_ontology[class_input["ontology"]] = []
        end
        class_id_by_ontology[class_input["ontology"]] << class_input["class"]
      end
      latest_submissions = []
      all_class_ids = []
      t0 = Time.now
      all_latest = retrieve_latest_submissions
      all_latest_by_id = Hash.new 
      all_latest.each do |acr,obj|
        all_latest_by_id[obj.ontology.id.to_s] = obj
      end
      class_id_to_ontology = Hash.new
      class_id_by_ontology.keys.each do |ont_id|
        if all_latest_by_id[ont_id]
          latest_submissions << all_latest_by_id[ont_id]
          all_class_ids << class_id_by_ontology[ont_id]
          class_id_by_ontology[ont_id].each do |cls_id|
            class_id_to_ontology[cls_id] = ont_id
          end
        end
      end
      all_class_ids.flatten!
      if latest_submissions.length == 0 or all_class_ids.length == 0
        reply({ resource_type => [] })
      else
        all_class_ids.uniq!
        all_class_ids.map! { |x| RDF::URI.new(x) }
        t0 = Time.now
        ont_classes = LinkedData::Models::Class.in(latest_submissions)
                      .ids(all_class_ids)
                      .include(goo_include).all

        to_reply = []
        ont_classes.each do |cls|
          if class_id_to_ontology[cls.id.to_s] and\
               all_latest_by_id[class_id_to_ontology[cls.id.to_s]]
            cls.submission = all_latest_by_id[class_id_to_ontology[cls.id.to_s]]
            to_reply << cls
          end 
        end
        reply({ resource_type => to_reply })
      end
    end

    private

    def fix_batch_params_for_request
      batch_include = []
      @params.each {|resource_type, values| batch_include << values["include"]}
      batch_include.compact!
      @params["include"] = batch_include.join(",")
      env["rack.request.query_hash"] = @params
    end

  end
end
