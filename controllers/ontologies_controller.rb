class OntologiesController < ApplicationController

  # Ontology acronym and name validation rules
  ACRONYM_RULES = <<-DOC
  Acronyms should conform to these rules:
  # it may contain a-z, A-Z, 0-9, dash, and underscore (no spaces)
  # it must start with a letter (upper or lower case)
  # it's length <= 16 characters
  # it must be unique (no ontology already owns it)
  DOC
  # regex to satisfy these criteria (tested at http://rubular.com/)
  ACRONYM_REGEX = /\A[A-Z]{1}[-_0-9A-Z]{0,15}\Z/


  namespace "/ontologies" do

    ##
    # Display all ontologies
    get do
      check_last_modified_collection(Ontology)
      allow_views = params['include_views'] ||= false
      if allow_views
        onts = Ontology.where.include(Ontology.goo_attrs_to_load(includes_param)).to_a
      else
        onts = Ontology.where.filter(Goo::Filter.new(:viewOf).unbound).include(Ontology.goo_attrs_to_load(includes_param)).to_a
      end
      reply onts
    end

    ##
    # Display the most recent submission of the ontology
    get '/:acronym' do
      ont = Ontology.find(params["acronym"]).first
      error 404, "You must provide a valid `acronym` to retrieve an ontology" if ont.nil?
      check_last_modified(ont)
      ont.bring(*Ontology.goo_attrs_to_load(includes_param))
      reply ont
    end

    ##
    # Ontology latest submission
    get "/:acronym/latest_submission" do
      ont = Ontology.find(params["acronym"]).first
      error 404, "You must provide a valid `acronym` to retrieve an ontology" if ont.nil?
      include_status = params["include_status"]
      check_last_modified(ont)
      ont.bring(:acronym, :submissions)
      if include_status
        latest = ont.latest_submission(status: include_status.to_sym)
      else
        latest = ont.latest_submission(status: :any)
      end
      latest.bring(*OntologySubmission.goo_attrs_to_load(includes_param)) if latest
      reply(latest || {})
    end

    ##
    # Create an ontology
    post do
      create_ontology
    end

    ##
    # Create an ontology with constructed URL
    put '/:acronym' do
      create_ontology
    end

    ##
    # Update an ontology
    patch '/:acronym' do
      ont = Ontology.find(params["acronym"]).include(Ontology.attributes).first
      error 422, "You must provide an existing `acronym` to patch" if ont.nil?

      populate_from_params(ont, params)
      if ont.valid?
        ont.save
      else
        error 422, ont.errors
      end

      halt 204
    end

    ##
    # Delete an ontology and all its versions
    delete '/:acronym' do
      ont = Ontology.find(params["acronym"]).first
      error 422, "You must provide an existing `acronym` to delete" if ont.nil?
      ont.delete
      halt 204
    end

    ##
    # Download the latest submission for an ontology
    get '/:acronym/download' do
      ont = Ontology.find(params["acronym"]).first
      error 422, "You must provide an existing `acronym` to download" if ont.nil?
      ont.bring(:viewingRestriction)
      check_access(ont)
      #
      # TODO: Also check for licensing restrictions, see
      # TODO: https://bmir-jira.stanford.edu/browse/NCBO-331
      #
      latest_submission = ont.latest_submission(status: :rdf)  # Should resolve to latest successfully loaded submission
      error 404, "There is no latest submission loaded for download" if latest_submission.nil?
      latest_submission.bring(:uploadFilePath)
      file_path = latest_submission.uploadFilePath
      if File.readable? file_path
        send_file file_path, :filename => File.basename(file_path)
      else
        error 500, "Cannot read latest submission upload file: #{file_path}"
      end
    end

    ##
    # Properties for given ontology
    # get '/:acronym/properties' do
    #   error 500, "Not implemented"
    # end

    private

    def create_ontology
      params ||= @params
      acronym = params["acronym"]

      # acronym must be well formed
      if ACRONYM_REGEX.match(acronym).nil?
        error 400, "Ontology acronym is not well formed.\n" + ACRONYM_RULES
      end

      # ontology acronym must be unique
      ont = Ontology.find(acronym).first
      if ont.nil?
        ont = instance_from_params(Ontology, params)
      else
        error_msg = <<-ERR
        Ontology already exists, see #{ont.id}
        To add a new submission, POST to: /ontologies/#{params["acronym"]}/submission.
        To modify the resource, use PATCH.
        ERR
        error 409, error_msg
      end

      # ontology name must be unique
      ont_names = Ontology.where.include(:name).to_a.map {|o| o.name }
      if ont_names.include?(ont.name)
        error 409, "Ontology name is already in use by another ontology."
      end

      if ont.valid?
        ont.save
      else
        error 422, ont.errors
      end

      reply 201, ont
    end
  end
end
