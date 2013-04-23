class AnnotatorController < ApplicationController
  namespace "/annotator" do

    # execute an annotator query
    get do
      text = params["text"]
      page_params = get_page_params(text, @params.dup)
      annotator = Annotator::Models::NcboAnnotator.new
      annotations = annotator.annotate(text)
      reply 200, annotations
    end

    post '/dictionary' do
      annotator = Annotator::Models::NcboAnnotator.new
      annotator.generate_dictionary_file
    end

    post '/cache' do
      annotator = Annotator::Models::NcboAnnotator.new
      annotator.create_term_cache
    end

    private

    def get_page_params(text, args={})
      raise error 400, "A text to be annotated must be supplied using the argument text=<text to be annotated>" if text.nil? || text.strip.empty?
      return args
    end
  end
end

