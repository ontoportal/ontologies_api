class ClassesController < ApplicationController

  namespace "/ontologies/:ontology/classes" do

    # Display a page for all classes
    get do
      includes_param_check
      ont, submission = get_ontology_and_submission
      cls_count = submission.class_count(LOGGER)
      error 403, "Unable to display classes due to missing metrics for #{submission.id.to_s}. Please contact the administrator." if cls_count < 0
      check_last_modified_segment(LinkedData::Models::Class, [ont.acronym])
      page, size = page_params
      ld = LinkedData::Models::Class.goo_attrs_to_load(includes_param)
      unmapped = ld.delete(:properties)
      page_data = LinkedData::Models::Class.in(submission).include(ld).page(page,size).page_count_set(cls_count).all

      if unmapped && page_data.length > 0
        LinkedData::Models::Class.in(submission).models(page_data).include(:unmapped).all
      end
      reply page_data
    end

    # Get root classes
    get '/roots' do
      includes_param_check
      ont, submission = get_ontology_and_submission
      check_last_modified_segment(LinkedData::Models::Class, [ont.acronym])
      load_attrs = LinkedData::Models::Class.goo_attrs_to_load(includes_param)
      unmapped = load_attrs.delete(:properties)
      roots = submission.roots(load_attrs)
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

      unmapped = ld.delete(:properties) ||
          (includes_param && includes_param.include?(:all))
      cls = get_class(submission, ld)
      if unmapped
        LinkedData::Models::Class.in(submission)
            .models([cls]).include(:unmapped).all
      end
      if includes_param.include?(:hasChildren)
        cls.load_has_children
      end
      if !load_children.nil? and load_children.length >0
        LinkedData::Models::Class.partially_load_children([cls],500,cls.submission)
        if includes_param.include?(:hasChildren)
          cls.children.each do |c|
            c.load_has_children
          end
        end
      end
      reply cls
    end

    # Get a paths_to_root view
    get '/:cls/paths_to_root' do
      includes_param_check
      ont, submission = get_ontology_and_submission
      check_last_modified_segment(LinkedData::Models::Class, [ont.acronym])
      ld = LinkedData::Models::Class.goo_attrs_to_load(includes_param)
      cls = get_class(submission, ld)
      reply cls.paths_to_root
    end

    # Get a tree view (returns the tree from the roots classes to the specified class)
    get '/:cls/tree' do
      includes_param_check
      # We override include values other than the following, user-provided include ignored
      display_attrs = "prefLabel,hasChildren,children,obsolete,subClassOf"
      params["display"] = display_attrs
      params["serialize_nested"] = true # Override safety check and cause children to serialize

      # Make sure Rack gets updated
      req = Rack::Request.new(env)
      req.update_param("display", display_attrs)
      req.update_param("serialize_nested", true)

      ont, submission = get_ontology_and_submission
      check_last_modified_segment(LinkedData::Models::Class, [ont.acronym])
      cls = get_class(submission)
      root_tree = cls.tree

      #add the other roots to the response
      roots = submission.roots(extra_include=[:hasChildren])

      # if this path' root does not get returned by the submission.roots call, manually add it
      roots << root_tree unless roots.map { |r| r.id }.include?(root_tree.id)

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
      includes_param_check
      ont, submission = get_ontology_and_submission
      check_last_modified_segment(LinkedData::Models::Class, [ont.acronym])
      cls = get_class(submission)
      error 404 if cls.nil?
      ancestors = cls.ancestors
      LinkedData::Models::Class.in(submission).models(ancestors)
          .include(:prefLabel,:synonym,:definition).all
      reply ancestors
    end

    # Get all descendants for given class
    get '/:cls/descendants' do
      includes_param_check
      ont, submission = get_ontology_and_submission
      check_last_modified_segment(LinkedData::Models::Class, [ont.acronym])
      page, size = page_params
      cls = get_class(submission,load_attrs=[])
      error 404 if cls.nil?
      page_data = cls.retrieve_descendants(page,size)
      LinkedData::Models::Class.in(submission).models(page_data)
          .include(:prefLabel,:synonym,:definition).all
      reply page_data
    end

    # Get all children of given class
    get '/:cls/children' do
      includes_param_check
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
      page_data.delete_if { |x| x.id.to_s == cls.id.to_s }
      if ld.include?(:hasChildren)
        page_data.each do |c|
          c.load_has_children
        end
      end
      reply page_data
    end

    # Get all parents of given class
    get '/:cls/parents' do
      includes_param_check
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
      reply cls.parents.select { |x| !x.id.to_s["owl#Thing"] }
    end

    private
    def includes_param_check
      if includes_param
        if includes_param.include?(:all)
          error(422, "all not allowed in include parameter for this endpoint")
        end
        if includes_param.include?(:ancestors) || includes_param.include?(:descendants)
          error(422,
                "in this endpoint ancestors and descendants are not allowed in include parameter")
        end
      end
    end

  end
end
