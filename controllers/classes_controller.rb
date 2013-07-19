class ClassesController < ApplicationController

  namespace "/ontologies/:ontology/classes" do

    # Display a page for all classes
    get do
      ont, submission = get_ontology_and_submission
      page, size = page_params
      ld = LinkedData::Models::Class.goo_attrs_to_load(includes_param)
      page_data = LinkedData::Models::Class.in(submission)
                                .include(ld)
                                .page(page,size)
                                .read_only
                                .all
      reply page_data
    end

    # Get root classes
    get '/roots' do
      ont, submission = get_ontology_and_submission
      load_attrs = LinkedData::Models::Class.goo_attrs_to_load(includes_param)
      include_childrenCount = load_attrs.include?(:childrenCount)
      roots = submission.roots(load_attrs, include_childrenCount)
      reply roots
    end

    # Display a single class
    get '/:cls' do
      ont, submission = get_ontology_and_submission
      cls = get_class(submission, LinkedData::Models::Class.goo_attrs_to_load(includes_param))
      reply cls
    end

    # Get a paths_to_root view
    get '/:cls/paths_to_root' do
      ont, submission = get_ontology_and_submission
      cls = get_class(submission, LinkedData::Models::Class.goo_attrs_to_load(includes_param))
      reply cls.paths_to_root
    end

    # Get a tree view
    get '/:cls/tree' do
      # We override include values other than the following, user-provided include ignored
      params["include"] = "prefLabel,childrenCount,children"
      env["rack.request.query_hash"] = params

      ont, submission = get_ontology_and_submission
      cls = get_class(submission)
      root_tree = cls.tree

      #add the other roots to the response
      roots = submission.roots(extra_include=nil, aggregate_children=true)
      roots.each_index do |i|
        r = roots[i]
        if r.id == root_tree.id
          roots[i] = root_tree
        else
          roots[i].instance_variable_set("@children",[])
          roots[i].loaded_attributes << :children
        end
      end
      reply roots
    end


    # Get all ancestors for given class
    get '/:cls/ancestors' do
      ont, submission = get_ontology_and_submission

      #I really want ancestors: [ user options ]
      load_attrs = load_attrs || LinkedData::Models::Class.goo_attrs_to_load(includes_param)
      load_attrs = [ ancestors: load_attrs ]
      cls = get_class(submission,load_attrs=load_attrs)
      error 404 if cls.nil?
      ancestors = cls.ancestors
      reply ancestors
    end

    # Get all descendants for given class
    get '/:cls/descendants' do
      ont, submission = get_ontology_and_submission
      page, size = page_params
      cls = get_class(submission,load_attrs=[])
      error 404 if cls.nil?
      ld = LinkedData::Models::Class.goo_attrs_to_load(includes_param)
      aggregates = LinkedData::Models::Class.goo_aggregates_to_load(ld)
      page_data_query = LinkedData::Models::Class.where(ancestors: cls).in(submission).include(ld)
      page_data_query.aggregate(*aggregates) unless aggregates.empty?
      page_data = page_data_query.page(page,size).all
      reply page_data
    end

    # Get all children of given class
    get '/:cls/children' do
      ont, submission = get_ontology_and_submission
      page, size = page_params
      cls = get_class(submission)
      error 404 if cls.nil?
      ld = LinkedData::Models::Class.goo_attrs_to_load(includes_param)
      aggregates = LinkedData::Models::Class.goo_aggregates_to_load(ld)
      page_data_query = LinkedData::Models::Class.where(parents: cls).in(submission).include(ld)
      page_data_query.aggregate(*aggregates) unless aggregates.empty?
      page_data = page_data_query.page(page,size).all
      reply page_data
    end

    # Get all parents of given class
    get '/:cls/parents' do
      ont, submission = get_ontology_and_submission
      cls = get_class(submission)
      ld = LinkedData::Models::Class.goo_attrs_to_load(includes_param)
      aggregates = LinkedData::Models::Class.goo_aggregates_to_load(ld)
      parents_query = LinkedData::Models::Class.where(children: cls).in(submission).include(ld)
      parents_query.aggregate(*aggregates) unless aggregates.empty?
      parents = parents_query.all
      if parents.nil?
        reply []
      else
        reply parents
      end
    end

    private

    def get_class(submission,load_attrs=nil)
      load_attrs = load_attrs || LinkedData::Models::Class.goo_attrs_to_load(includes_param)
      cls_uri = RDF::URI.new(params[:cls])
      if !cls_uri.valid?
        error 400, "The input class id '#{params[:cls]}' is not a valid IRI"
      end
      aggregates = LinkedData::Models::Class.goo_aggregates_to_load(load_attrs)
      cls = LinkedData::Models::Class.find(cls_uri).in(submission)
      cls = cls.include(load_attrs) if load_attrs && load_attrs.length > 0
      cls.aggregate(*aggregates) unless aggregates.empty?
      cls = cls.first
      if cls.nil?
        error 404,
           "Resource '#{params[:cls]}' not found in ontology #{submission.ontology.acronym} submission #{submission.submissionId}"
      end
      return cls
    end

    def get_ontology_and_submission
      ont = Ontology.find(@params["ontology"])
              .include(:acronym)
              .include(submissions: [:submissionId, submissionStatus: [:code], ontology: [:acronym]])
              .first
      error(404, "Ontology '#{@params["ontology"]}' not found.") if ont.nil?
      submission = nil
      if @params.include? "ontology_submission_id"
        submission = ont.submission(@params[:ontology_submission_id])
        error 404, "You must provide an existing submission ID for the #{@params["acronym"]} ontology" if submission.nil?
      else
        submission = ont.latest_submission
      end
      error 404,  "Ontology #{@params["ontology"]} submission not found." if submission.nil?
      status = submission.submissionStatus
      if !status.parsed?
        error 404,  "Ontology #{@params["ontology"]} submission #{submission.submissionId} has not been parsed."
      end
      if submission.nil?
        error 404, "Ontology #{@params["acronym"]} does not have any submissions" if submission.nil?
      end
      return ont, submission
    end

  end
end
