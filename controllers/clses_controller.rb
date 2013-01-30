class ClsesController
  namespace "/ontologies/:ontology/classes" do
    # Display all classes
    get do
    end

    # Get root classes
    get '/roots' do
      ont = Ontology.find(params["ontology"])
      error 400, "You must provide an existing `acronym` to retrieve roots" if ont.nil?
      ont.load unless ont.loaded?
      submission = nil
      if params.include? :ontology_submission_id
        submission = ont.submission(params[:ontology_submission_id])
        error 400, "You must provide an existing submission ID for the #{params["acronym"]} ontology" if submission.nil?
      else
        submission = ont.latest_submission
      end
      submission.load unless submission.loaded?
      status = submission.submissionStatus
      if submission.nil?
        error 400, "Ontology #{params["acronym"]} does not have any submissions" if submission.nil?
      end
      roots = submission.roots
      roots.each do |r|
        r.load_labels unless r.loaded_labels?
      end
      reply roots
    end

    #
    # Display a single class
    get '/:cls' do
      submission = params[:ontology_submission_id]
    end



    # Get a tree view
    get '/:cls/tree' do
    end

    # Get all ancestors for given class
    get '/:cls/ancestors' do
    end

    # Get all descendants for given class
    get '/:cls/descendants' do
    end

    # Get all children of given class
    get '/:cls/children' do
    end

    # Get all parents of given class
    get '/:cls/parents' do
    end

  end
end
