class ClassesController

  namespace "/ontologies/:ontology/classes" do

    # Display a page for all classes
    get do
      ont, submission = get_ontology_and_submission
      page, size = get_page_params
      clss = submission.classes :load_attrs => [:prefLabel, :synonym, :definition]
      page_class ={ :classes => clss.page(page, size),
              :count => clss.length,
              :page => page,
              :size => size }
      page_class[:next] = page + 1 if clss.page(page + 1, size)
      reply page_class
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
      page, size = get_page_params
      cls = get_class(submission,load_attrs=[])
      ld = { prefLabel: true, synonym: true, definition: true }
      page_data = LinkedData::Models::Class.page submission: submission, parents: cls,
                                                 page: page, size: size,
                                                 load_attrs: ld,
                                                 query_options: { rules: "SUBC+SUBP" }
      reply page_data
    end

    # Get all children of given class
    get '/:cls/children' do
      ont, submission = get_ontology_and_submission
      page, size = get_page_params
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

    #TODO Eventually this needs to be moved to a wider context.
    def get_page_params
      page = @params["page"] || 1
      size = @params["size"] || 50
      begin
        page = Integer(page)
        size = Integer(size)
      rescue
        error 400, "Page number and page size must integers. page no. is #{page} and page size is #{size}."
      end
      raise error 400, "Limit page size is 500. Page size in request is #{size}" if size > 500
      return page, size
    end

    private
    def get_class(submission,load_attrs=nil)
      load_attrs = load_attrs || [:prefLabel, :synonym, :definition]
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
      ont = Ontology.find(@params["ontology"])
      error 400, "You must provide an existing `acronym` to retrieve roots" if ont.nil?
      ont.load unless ont.loaded?
      submission = nil
      if @params.include? "ontology_submission_id"
        submission = ont.submission(@params[:ontology_submission_id])
        error 400, "You must provide an existing submission ID for the #{@params["acronym"]} ontology" if submission.nil?
      else
        submission = ont.latest_submission
      end
      error 400,  "Ontology #{@params["ontology"]} submission not found." if submission.nil?
      submission.load unless submission.loaded?
      status = submission.submissionStatus
      status.load unless status.loaded?
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
