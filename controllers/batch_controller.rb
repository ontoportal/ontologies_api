class BatchController < ApplicationController
  namespace "/batch" do
    post do "/"
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
        class_id_by_ontology[class_input["ontology"]] = [] unless class_id_by_ontology.include? class_input["ontology"]
        class_id_by_ontology[class_input["ontology"]] << class_input["class"]
      end
      classes = []
      class_id_by_ontology.each do |ont_id,class_ids|
        ont_id = ont_id.sub(LinkedData.settings.rest_url_prefix, Goo.id_prefix)
        class_ids.uniq!
        class_ids.map! { |id| RDF::URI.new(id) }
        ont = LinkedData::Models::Ontology.find(RDF::URI.new(ont_id))
                    .include(submissions: [:submissionId]).first
        error 404, "Ontology #{ont_id} could not be found" if ont.nil?
        latest = ont.latest_submission
        latest.bring(ontology:[:acronym])
        classes.concat(LinkedData::Models::Class.in(latest).ids(class_ids).include(goo_include.map{|x| x.to_sym}).read_only.all)
      end
      reply({ resource_type => classes })
    end
  end
end
