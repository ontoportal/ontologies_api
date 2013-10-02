class ClassesController < ApplicationController

  namespace "/ontologies/:ontology/classes" do

    # Display a page for all classes
    get do
      error 422 if (includes_param && includes_param.include?(:all))
      ont, submission = get_ontology_and_submission
      check_last_modified_segment(LinkedData::Models::Class, [ont.acronym])
      page, size = page_params
      ld = LinkedData::Models::Class.goo_attrs_to_load(includes_param)
      unmapped = ld.delete(:properties)
      page_data = LinkedData::Models::Class.in(submission)
                                .include(ld)
                                .page(page,size)
                                .all
      if unmapped && page_data.length > 0
        LinkedData::Models::Class.in(submission).models(page_data).include(:unmapped).all
      end
      reply page_data
    end

    # Get root classes
    get '/roots' do
      error 422 if (includes_param && includes_param.include?(:all))
      ont, submission = get_ontology_and_submission
      check_last_modified_segment(LinkedData::Models::Class, [ont.acronym])
      load_attrs = LinkedData::Models::Class.goo_attrs_to_load(includes_param)
      unmapped = load_attrs.delete(:properties)
      include_childrenCount = load_attrs.include?(:childrenCount)
      roots = submission.roots(load_attrs, include_childrenCount)
      if unmapped && roots.length > 0
        LinkedData::Models::Class.in(submission).models(roots).include(:unmapped).all
      end
      reply roots
    end

    # Display a single class
    get '/:cls' do
      ont, submission = get_ontology_and_submission
      check_last_modified_segment(LinkedData::Models::Class, [ont.acronym])
      ld = LinkedData::Models::Class.goo_attrs_to_load(includes_param)

      load_children = ld.delete :children
      if !load_children
        load_children = ld.select { |x| x.instance_of?(Hash) && x.include?(:children) }
        if load_children
          ld = ld.select { |x| !(x.instance_of?(Hash) && x.include?(:children)) }
        end
      end

      unmapped = ld.delete(:properties) || (includes_param && includes_param.include?(:all))
      cls = get_class(submission, ld)
      if unmapped
        LinkedData::Models::Class.in(submission).models([cls]).include(:unmapped).all
      end
      if load_children
        LinkedData::Models::Class.partially_load_children([cls],500,cls.submission)
      end
      reply cls
    end

    # Get a paths_to_root view
    get '/:cls/paths_to_root' do
      error 422 if (includes_param && includes_param.include?(:all))
      ont, submission = get_ontology_and_submission
      check_last_modified_segment(LinkedData::Models::Class, [ont.acronym])
      ld = LinkedData::Models::Class.goo_attrs_to_load(includes_param)
      cls = get_class(submission, ld)
      reply cls.paths_to_root
    end

    # Get a tree view
    get '/:cls/tree' do
      error 422 if (includes_param && includes_param.include?(:all))
      # We override include values other than the following, user-provided include ignored
      params["include"] = "prefLabel,childrenCount,children"
      env["rack.request.query_hash"] = params

      ont, submission = get_ontology_and_submission
      check_last_modified_segment(LinkedData::Models::Class, [ont.acronym])
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
      check_last_modified_segment(LinkedData::Models::Class, [ont.acronym])
      cls = get_class(submission,load_attrs=[:ancestors])
      error 404 if cls.nil?
      ancestors = cls.ancestors
      LinkedData::Models::Class.in(submission).models(ancestors).include(:prefLabel).all
      reply ancestors
    end

    # Get all descendants for given class
    get '/:cls/descendants' do
      ont, submission = get_ontology_and_submission
      check_last_modified_segment(LinkedData::Models::Class, [ont.acronym])
      page, size = page_params
      cls = get_class(submission,load_attrs=[])
      error 404 if cls.nil?
      page_data_query = LinkedData::Models::Class.where(ancestors: cls)
                          .in(submission).include(:prefLabel)
      page_data = page_data_query.page(page,size).all
      reply page_data
    end

    # Get all children of given class
    get '/:cls/children' do
      error 422 if (includes_param && includes_param.include?(:all))
      ont, submission = get_ontology_and_submission
      check_last_modified_segment(LinkedData::Models::Class, [ont.acronym])
      page, size = page_params
      cls = get_class(submission)
      error 404 if cls.nil?
      ld = LinkedData::Models::Class.goo_attrs_to_load(includes_param)
      unmapped = ld.delete(:properties)
      aggregates = LinkedData::Models::Class.goo_aggregates_to_load(ld)
      page_data_query = LinkedData::Models::Class.where(parents: cls).in(submission).include(ld)
      page_data_query.aggregate(*aggregates) unless aggregates.empty?
      page_data = page_data_query.page(page,size).all
      if unmapped
        LinkedData::Models::Class.in(submission).models(page_data).include(:unmapped).all
      end
      reply page_data
    end

    # Get all parents of given class
    get '/:cls/parents' do
      error 422 if (includes_param && includes_param.include?(:all))
      ont, submission = get_ontology_and_submission
      check_last_modified_segment(LinkedData::Models::Class, [ont.acronym])
      cls = get_class(submission)
      ld = LinkedData::Models::Class.goo_attrs_to_load(includes_param)
      unmapped = ld.delete(:properties)
      if ld.include?(:children)
        error 422, "The parents call does not allow children attribute to be included"
      end

      cls.bring(:parents)
      reply [] if cls.parents.length == 0

      aggregates = LinkedData::Models::Class.goo_aggregates_to_load(ld)
      parents_query = LinkedData::Models::Class.in(submission).models(cls.parents).include(ld)
      parents_query.aggregate(*aggregates) unless aggregates.empty?
      parents = parents_query.all

      if unmapped
        LinkedData::Models::Class.in(submission).models(cls.parents).include(:unmapped).all
      end
      reply cls.parents
    end

    private

    def get_class(submission,load_attrs=nil)
      load_attrs = load_attrs || LinkedData::Models::Class.goo_attrs_to_load(includes_param)
      load_children = load_attrs.delete :children
      if !load_children
        load_children = load_attrs.select { |x| x.instance_of?(Hash) && x.include?(:children) }
        if load_children
          load_attrs = load_attrs.select { |x| !(x.instance_of?(Hash) && x.include?(:children)) }
        end
      end
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
      if load_children
        LinkedData::Models::Class.partially_load_children([cls],500,cls.submission)
      end
      return cls
    end

  end
end
