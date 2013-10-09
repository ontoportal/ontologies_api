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
      text = params["text"]
      raise error 400, "A text to be annotated must be supplied using the argument text=<text to be annotated>" if text.nil? || text.strip.empty?
      acronyms = restricted_ontologies_to_acronyms(params)
      semantic_types = semantic_types_param
      max_level = params["max_level"].to_i || 0
      mapping_types = params["mappings"]

      if mapping_types
        mapping_types = mapping_types.is_a?(Array) ? mapping_types : []
      end
      exclude_nums = params["exclude_numbers"].eql?("true")
      stop_words = params["stop_words"]
      min_term_size = params["minimum_match_length"]
      min_term_size = min_term_size.to_i if min_term_size

      annotator = Annotator::Models::NcboAnnotator.new
      annotator.stop_words = stop_words if stop_words
      annotations = annotator.annotate(text,
                                       acronyms,
                                       semantic_types,
                                       exclude_nums,
                                       max_level,
                                       expand_with_mappings=mapping_types,
                                       min_term_size)
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

