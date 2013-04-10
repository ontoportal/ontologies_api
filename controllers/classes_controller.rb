class ClassesController < ApplicationController

  namespace "/ontologies/:ontology/classes" do

    # Display a page for all classes
    get do
      ont, submission = get_ontology_and_submission
      page, size = page_params
      ld = LinkedData::Models::Class.goo_attrs_to_load(includes_options)
      page_data = LinkedData::Models::Class.page submission: submission,
                                                 page: page, size: size,
                                                 load_attrs: ld,
                                                 query_options: { rules: "SUBP" }
      reply page_data
    end

    # Get root classes
    get '/roots' do
      ont, submission = get_ontology_and_submission
      roots = submission.roots
      reply roots
    end

    #
    # Display a single class
    get '/:cls' do
      ont, submission = get_ontology_and_submission
      cls = get_class(submission)
      reply cls
    end

    # Get a tree view
    get '/:cls/tree' do
      ont, submission = get_ontology_and_submission
      cls = get_class(submission)
      reply cls.paths_to_root
    end

    # Get all ancestors for given class
    get '/:cls/ancestors' do
      ont, submission = get_ontology_and_submission
      cls = get_class(submission)
      ancestors = cls.ancestors
      reply ancestors
    end

    # Get all descendants for given class
    get '/:cls/descendants' do
      ont, submission = get_ontology_and_submission
      page, size = page_params
      ld = LinkedData::Models::Class.goo_attrs_to_load(includes_options)
      cls = get_class(submission,load_attrs=[])
      page_data = LinkedData::Models::Class.page submission: submission, parents: cls,
                                                 page: page, size: size,
                                                 load_attrs: ld,
                                                 query_options: { rules: "SUBC+SUBP" }
      reply page_data
    end

    # Get all children of given class
    get '/:cls/children' do
      ont, submission = get_ontology_and_submission
      page, size = page_params
      cls = get_class(submission,load_attrs=[])
      ld = { prefLabel: true, synonym: true, definition: true }
      page_data = LinkedData::Models::Class.page submission: submission, parents: cls,
                                                 page: page, size: size,
                                                 load_attrs: ld,
                                                 query_options: { rules: "SUBP" }
      reply page_data
    end

    # Get all parents of given class
    get '/:cls/parents' do
      ont, submission = get_ontology_and_submission
      cls = get_class(submission)
      parents = cls.parents
      if parents.nil?
        reply []
      else
        reply parents
      end
    end

    private

    def get_class(submission,load_attrs=nil)
      load_attrs = load_attrs || { prefLabel: true, synonym: true, definition: true, childrenCount: true }
      if !(SparqlRd::Utils::Http.valid_uri? params[:cls])
        error 400, "The input class id '#{params[:cls]}' is not a valid IRI"
      end
      cls = LinkedData::Models::Class.find(RDF::IRI.new(params[:cls]), submission: submission,
                                           :load_attrs => load_attrs)
      if cls.nil?
        submission.ontology.load unless submission.ontology.loaded?
        error 404, "Resource '#{params[:cls]}' not found in ontology #{submission.ontology.acronym} submission #{submission.submissionId}"
      end
      return cls
    end

    def get_ontology_and_submission
      ont = Ontology.find(@params["ontology"], load_attrs: { acronym: true, submissions: { submissionId: true, submissionStatus: { code: true } } })
      error 400, "You must provide an existing `acronym` to retrieve roots" if ont.nil?
      submission = nil
      if @params.include? "ontology_submission_id"
        submission = ont.submission(@params[:ontology_submission_id])
        error 400, "You must provide an existing submission ID for the #{@params["acronym"]} ontology" if submission.nil?
      else
        submission = ont.latest_submission
      end
      error 400,  "Ontology #{@params["ontology"]} submission not found." if submission.nil?
      status = submission.submissionStatus
      if !status.parsed?
        error 400,  "Ontology #{@params["ontology"]} submission #{submission.submissionId} has not been parsed."
      end
      if submission.nil?
        error 400, "Ontology #{@params["acronym"]} does not have any submissions" if submission.nil?
      end
      return ont, submission
    end

  end
end
