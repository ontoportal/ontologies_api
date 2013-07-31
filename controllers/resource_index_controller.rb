
require 'ncbo_resource_index_client'
require 'set'

class ResourceIndexController < ApplicationController

  # Note: methods from resource_index_helper.rb :
  #  -  get_options(params)
  #  -  get_ontology_virtual_id(ontology_acronym)

  namespace "/resource_index" do


    # http://rest.bioontology.org/resource_index/ontologies
    # Return all ontologies
    get "/ontologies" do
      options = get_options(params)
      result = NCBO::ResourceIndex.ontologies(options)
      check404(result, "No ontologies found by resource index client.")
      LOGGER.info("/resource_index/ontologies: #ontologies in resource index = #{result.length}")
      ontology_array = massage_ontologies(result, options)
      check500(ontology_array, "Failed to resolve resource index data with triple store data.")
      reply ontology_array
    end

    get '/search' do
      options = get_options(params)
      classes = get_classes(params)
      error 404, "You must provide valid `classes` to retrieve resources" if classes.empty?
      options[:elementDetails] = true
      result = NCBO::ResourceIndex.find_by_concept(classes, options)
      check404(result, "No concepts found.")
      #
      # TODO: Fix the get_annotated_class method (REDIS db failures), called by massage_search
      #
      search_array = massage_search(result, options)
      page = page_object(search_array)
      reply page
    end

    get '/ranked_elements' do
      options = get_options(params)
      classes = get_classes(params)
      error 404, "You must provide valid `classes` to retrieve resources" if classes.empty?
      result = NCBO::ResourceIndex.ranked_elements(classes, options)
      check404(result, "No elements found.")
      # result.resources.delete_if {|r| r[:elements].empty? }
      result.resources.each do |r|
        r[:elements] = massage_elements(r[:elements]) if not r[:elements].empty?
      end
      # TODO: Massage additional components (result.concepts)?
      page = page_object(result.resources)
      reply page
    end

    # Return all resources
    get "/resources" do
      options = get_options(params)
      result = NCBO::ResourceIndex.resources(options)
      check404(result, "No resources found.")
      reply massage_resources(result)
    end

    # Return specific resources
    get "/resources/:resources" do
      options = get_options(params)
      result = NCBO::ResourceIndex.resources_hash(options)
      check404(result, "No resources found.")
      resources_filtered = []
      options[:resourceids].each do |r|
        rid = r.downcase.to_sym
        resources_filtered.push result[rid] if result.keys.include? rid
      end
      reply massage_resources(resources_filtered)
    end

    # Return a specific element from a specific resource
    get "/resources/:resources/elements/:elements" do
      options = get_options(params)
      result = NCBO::ResourceIndex.element(params["elements"], params["resources"], options)
      check404(result, "No element found.")
      element = massage_element(result, options[:elementDetails])
      #element = { "id" => result.id }
      #fields = {}
      #result.text.each do |name, description|
      #  # TODO: Parse the text field to translate the term IDs into a list of URIs?
      #  #"text"=> "1351/D020224> 1351/D019295> 1351/D008969> 1351/D001483> 1351/D017398> 1351/D000465> 1351/D005796> 1351/D008433> 1351/D009690> 1351/D005091",
      #  #
      #  # Parse the associated ontologies to return a list of ontology URIs
      #  ontIDs = [result.ontoIds[name]].compact  # Wrap Fixnum or Array into Array
      #  ontIDs.delete_if {|x| x == 0 }
      #  ontIDs.each_with_index do |id, i|  # Try to convert to ontology URIs
      #    uri = ontology_uri_from_virtual_id(id)
      #    if uri.nil?
      #      ontIDs[i] = id.to_s # conform to expected data type for JSON validation
      #    else
      #      ontIDs[i] = uri
      #    end
      #  end
      #  weight = 0.0
      #  result.weights.each {|hsh| weight = hsh[:weight] if hsh[:name] == name}
      #  fields[name] = {
      #      "associatedClasses" => [],
      #      "associatedOntologies" => ontIDs,
      #      "text" => description,
      #      "weight" => weight
      #  }
      #end
      #element["fields"] = fields
      reply element
    end


    def check404(response, message)
      error 404, message if response.nil?
      if response.is_a? Array
        error 404, message if response.empty?
      end
      if response.is_a? Hash
        error 404, message if response.empty?
      end
    end

    def check500(response, message)
      error 500, message if response.nil?
      if response.is_a? Array
        error 500, message if response.empty?
      end
      if response.is_a? Hash
        error 500, message if response.empty?
      end
    end

    ##
    # Data massage methods.
    #

    def massage_ontologies(old_response, options)
      ri_ontology_acronyms = []
      old_response.each do |ont|
        acronym = acronym_from_virtual_id(ont[:virtualOntologyId])  # from resource_index_helper (REDIS lookup)
        if acronym.nil?
          # The RI contains an ontology that is not in the new API service, or the
          # GOO/REDIS store doesn't contain the lookup data?
          LOGGER.info("/resource_index/ontologies: failed lookup of ontology URI for #{ont[:virtualOntologyId]} - #{ont[:ontologyName]}")
        else
          ri_ontology_acronyms.push(acronym)
        end
      end
      # Triple Store ontologies - not equivalent to resource index ontologies.
      ont_attributes = LinkedData::Models::Ontology.goo_attrs_to_load()
      linked_ontologies = LinkedData::Models::Ontology.where.include(ont_attributes).all
      # Return only the triple store ontologies with data in the resource index
      linked_ontologies.delete_if {|ont| not ri_ontology_acronyms.include? ont.acronym  }
      return linked_ontologies
    end

    def massage_search(old_response, options)
      resources = {}
      old_response.each do |resource|
        elements = {}
        annotations = []
        resource.annotations.each do |a|
          annotated_class = get_annotated_class(a)
          # NOTE: Skipping nil class_uri values, could mess with paging details
          # The nil values are marginal cases for OBO terms
          next if annotated_class.nil?
          # NOTE: options[:scored] is not related to element weights.
          element = massage_element(a.element, options[:elementDetails])
          el_id = element["id"]
          elements[el_id] = element["fields"] unless elements.include?(el_id)
          annotations.push massage_search_annotation(a, annotated_class)
        end
        # TODO: add search option to exclude 0-element resources?
        resources[resource.resource] = {
            "id" => resource.resource,
            "annotations" => annotations,
            "annotatedElements" => elements
        }
      end
      return resources.values
    end

    # @param resource_annotation [{:localConceptId => 'version_id/term_id'}]
    # @return nil or annotated_class = { :id => 'term_uri', :ontology => 'ontology_uri'}
    def get_annotated_class(a)
      version_id, short_id = a.concept[:localConceptId].split('/')
      class_uri = uri_from_short_id(version_id, short_id)
      return nil if class_uri.nil?
      # undo the comment for testing purposes, only when class_uri.nil?
      #class_uri = a.concept[:localConceptId] if class_uri.nil?
      ontology_acronym = acronym_from_version_id(version_id)
      return nil if ontology_acronym.nil?
      ontology_uri = ontology_uri_from_acronym(ontology_acronym)
      return nil if ontology_uri.nil?

      ontology = LinkedData::Models::Ontology.read_only(id: RDF::IRI.new(ontology_uri), acronym: ontology_uri.split("/").last)
      submission = LinkedData::Models::OntologySubmission.read_only(id: RDF::IRI.new(ontology_uri+"/submissions/latest"), ontology: ontology)
      annotated_class = LinkedData::Models::Class.read_only(id: RDF::IRI.new(class_uri), submission: submission)

      # annotated_class = LinkedData::Models::Class.read_only(RDF::IRI.new(class_uri), {})
      # annotated_class.submissionAcronym = ontology_uri
      return annotated_class
    end

    def massage_search_annotation(a, annotated_class)
      # annotations is a hash of annotation hashes,
      # this method will modify it directly (by reference).
      annotationTypeMap = {
          "mgrepContext" => "direct",
          "mappingContext" => "mapping",
          "isaContext" => "hierarchy"
      }
      annotation = {
          :annotatedClass => annotated_class,
          :annotationType => annotationTypeMap[ a.context[:contextType] ],
          :elementField => a.context[:contextName],
          :elementId => a.element[:localElementId],
          :from => a.context[:from],
          :to => a.context[:to],
          #:score => a.score
      }
      return annotation
    end

    def massage_elements(element_array)
      # TODO: change this to use map! instead of each loop?
      elements = []
      element_array.each { |e| elements.push massage_element(e) }
      return elements
    end

    def massage_element(e, with_fields=true)
      # Designed to handle e data as ranked element or resource element
      if e.class == NCBO::ResourceIndex::Element
        # This is a resource element
        id = e.id
      else
        # This is a ranked element
        id = e[:localElementId]
      end
      element = {}
      element['id'] = id
      if with_fields
        if e.class == NCBO::ResourceIndex::Element
          # This is a resource element
          text = e.text
          ontoIds = e.ontoIds
          weights = e.weights
        else
          # This is a ranked element
          text = e[:text]
          ontoIds = e[:ontoIds]
          weights = e[:weights]
        end
        element['fields'] = massage_element_fields(text, ontoIds, weights) if with_fields
      end
      return element
    end

    def massage_element_fields(text, ontoIds, weights)
      fields = {}
      text.each do |name, description|
        # Parse the associated ontologies to return a list of ontology URIs
        ontIDs = [ontoIds[name]].compact  # Wrap Fixnum or Array into Array
        associatedOntologies = ontologyIDs2URIs(ontIDs)
        associatedClasses = termIDs2classes(description, associatedOntologies)
        weight = 0.0
        weights.each {|hsh| weight = hsh[:weight] if hsh[:name] == name}
        fields[name] = {
            "associatedClasses" => associatedClasses,
            "associatedOntologies" => associatedOntologies,
            "text" => description,
            "weight" => weight
        }
      end
      return fields
    end

    def ontologyIDs2URIs(ontIDs)
      ontURIs = []
      ontIDs.delete_if {|x| x <= 0 }
      ontIDs.each do |id|     # Try to convert to ontology URIs
        uri = ontology_uri_from_virtual_id(id)
        next if uri.nil?
        # ontIDs[i] = id.to_s # conform to data type for JSON validation
        ontURIs.push uri
      end
      return ontURIs
    end

    def termIDs2classes(description, associatedOntologies)
      associatedClasses = []
      # Parse the 'description' field to translate the term IDs into a list of URIs?
      # "description"=> "1351/D020224> 1351/D019295> 1351/D008969> 1351/D001483> 1351/D017398> 1351/D000465> 1351/D005796> 1351/D008433> 1351/D009690> 1351/D005091",
      if description.include? '> '
        description.split('> ').each do |term|
          ont_id, term_short_id = term.split('/')
          ont_uri = ontology_uri_from_virtual_id(ont_id)
          next if ont_uri.nil?
          associatedOntologies.push ont_uri unless associatedOntologies.include? ont_uri
          ont_acronym = acronym_from_virtual_id(ont_id)
          next if ont_acronym.nil?
          term_uri = uri_from_short_id_with_acronym(ont_acronym, term_short_id)
          next if term_uri.nil?
          ontology = LinkedData::Models::Ontology.read_only(id: RDF::IRI.new(ont_uri), acronym: ont_acronym)
          submission = LinkedData::Models::OntologySubmission.read_only(id: RDF::IRI.new(ont_uri+"/submissions/latest"), ontology: ontology)
          term_model = LinkedData::Models::Class.read_only(id: RDF::IRI.new(term_uri), submission: submission)
          associatedClasses.push term_model
        end
      end
      return associatedClasses
    end


    def massage_resources(resource_array)
      # Remove resource content
      resource_array.each do |r|
        r.delete :workflowCompletedDate
        r.delete :contexts
      end
      return resource_array.sort {|a,b| a[:resourceId].downcase <=> b[:resourceId].downcase}
    end

  end # namespace "/resource_index"

end # class ResourceIndexController
