require 'active_support/all'

class RecommenderController < ApplicationController
  namespace "/recommender" do

    get do
      recommend
    end

    post do
      recommend
    end

    # Executes a Recommender query.
    # Parameters:
    # - input: text or keywords (required)
    # - ontologies: {ontology_acronym1, ontology_acronym2, ..., ontology_acronymN}
    # - input_type: 1 (text), 2 (keywords)
    # - output_type: 1 (single ontologies), 2 (ontology sets)
    # - max_elements_set: maximum number of ontologies per set
    # - wc: weight for coverage score
    # - ws: weight for specialization score
    # - wa: weight for acceptance score
    # - wd: weight for detail score
    def recommend(params=nil)
      params ||= @params
      # input = 'melanoma, white blood cell, melanoma,     arm, cavity of stomach'
      input = params['input']
      input_type = params['input_type']
      output_type = params['output_type']
      max_elements_set = params['max_elements_set']
      wc = params['wc']
      ws = params['ws']
      wa = params['wa']
      wd = params['wd']

      # Set defaults
      OntologyRecommender.config

      # Parameters validation
      # input
      if input.nil? || input.strip.empty? then raise error 400, 'A text or keywords to be analyzed by the recommender must be supplied using the argument input=<input>' end
      # input_type
      if input_type.nil? then input_type = OntologyRecommender.settings.input_type
      elsif input_type.strip.empty? || (input_type.to_i != 1 && input_type.to_i != 2) then raise error 400, 'Invalid input type. Valid input types are: 1 (text) and 2 (keywords)'
      else input_type = input_type.to_i
      end
      # output_type
      if output_type.nil? then output_type = OntologyRecommender.settings.output_type
      elsif output_type.strip.empty? || (output_type.to_i != 1 && output_type.to_i != 2) then raise error 400, 'Invalid output type. Valid output types are: 1 (ontologies) and 2 (ontology sets)'
      else output_type = output_type.to_i
      end
      # max_elements_set
      if max_elements_set.nil? then max_elements_set = OntologyRecommender.settings.max_elements_set
      elsif max_elements_set.strip.empty? || (max_elements_set.to_i < 2 || max_elements_set.to_i > 4) then raise error 400, 'Invalid value for max_elements_set. Valid values are: 2, 3, 4'
      else max_elements_set = max_elements_set.to_i
      end
      # wc
      if wc.nil? then wc =  OntologyRecommender.settings.wc
      elsif wc.strip.empty? || wc.to_f < 0 then raise error 400, 'Invalid value for wc. It must be greater or equal to zero'
      else wc = wc.to_f
      end
      # ws
      if ws.nil? then ws =  OntologyRecommender.settings.ws
      elsif ws.strip.empty? || ws.to_f < 0 then raise error 400, 'Invalid value for ws. It must be greater or equal to zero'
      else ws = ws.to_f
      end
      # wa
      if wa.nil? then wa =  OntologyRecommender.settings.wa
      elsif wa.strip.empty? || wa.to_f < 0 then raise error 400, 'Invalid value for wa. It must be greater or equal to zero'
      else wa = wa.to_f
      end
      # wd
      if wd.nil? then wd =  OntologyRecommender.settings.wd
      elsif wd.strip.empty? || wd.to_f < 0 then raise error 400, 'Invalid value for wd. It must be greater or equal to zero'
      else wd = wd.to_f
      end
      # sum of weights
      if (wc + ws + wa + wd <= 0) then raise error 400, 'The sum of the weights must be greater than zero' end

      acronyms = restricted_ontologies_to_acronyms(params)
      recommender = OntologyRecommender::Recommender.new
      ranking = recommender.recommend(input, input_type, output_type, max_elements_set, acronyms, wc, ws, wa, wd)
      reply 200, ranking
    end
  end
end