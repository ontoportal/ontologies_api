class AnnotatorController < ApplicationController
  namespace "/annotator" do

    post do
      process_annotation
    end

    get do
      process_annotation
    end

    # execute an annotator query
    def process_annotation(params=nil)
      params ||= @params
      text = params['text']
      raise error 400, 'A text to be annotated must be supplied using the argument text=<text to be annotated>' if text.nil? || text.strip.empty?
      acronyms = restricted_ontologies_to_acronyms(params)
      semantic_types = semantic_types_param
      max_level = params['max_level'].to_i                   # default = 0

      longest_only = params['longest_only'].eql?('true')  # default = false
      expand_with_mappings = params['mappings'].eql?('true')  # default = false
      exclude_nums = params['exclude_numbers'].eql?('true')  # default = false
      whole_word_only = params['whole_word_only'].eql?('false') ? false : true  # default = true
      with_synonyms = params['with_synonyms'].eql?('false') ? false : true  # default = true
      min_term_size = params['minimum_match_length'].to_i    # default = 0
      recognizer = (Annotator.settings.enable_recognizer_param && params['recognizer']) || 'Mgrep'
      annotator = nil

      # see if a name of the recognizer has been passed in, use default if not or error
      begin
        recognizer = recognizer.slice(0, 1).capitalize + recognizer.slice(1..-1)
        clazz = "Annotator::Models::Recognizers::#{recognizer}".split('::').inject(Object) {|o, c| o.const_get c}
        annotator = clazz.new
      rescue Exception => e
        annotator = Annotator::Models::Recognizers::Mgrep.new
      end

      if params['stop_words']
        annotator.stop_words = params['stop_words']
      end

      annotations = annotator.annotate(text, {
          ontologies: acronyms,
          semantic_types: semantic_types,
          filter_integers: exclude_nums,
          expand_hierarchy_levels: max_level,
          expand_with_mappings: expand_with_mappings,
          min_term_size: min_term_size,
          whole_word_only: whole_word_only,
          with_synonyms: with_synonyms,
          longest_only: longest_only
      })

      if params["populate_from_search"]
        orig_classes = annotations.map {|a| a.annotatedClass}
        classes_hash = populate_classes_from_search(orig_classes)
        annotations.each {|a| a.instance_variable_set("@annotatedClass", classes_hash[a.annotatedClass.submission.ontology.id.to_s + a.annotatedClass.id.to_s])}
      end

      reply 200, annotations
    end

    get '/dictionary' do
      error 403, "Access denied" unless current_user && current_user.admin?
      annotator = Annotator::Models::NcboAnnotator.new
      annotator.generate_dictionary_file
    end

    get '/cache' do
      error 403, "Access denied" unless current_user && current_user.admin?
      annotator = Annotator::Models::NcboAnnotator.new
      annotator.create_term_cache
    end

    private

    def get_page_params(text, args={})
      return args
    end

  end
end

