require 'sinatra/base'

module Sinatra
  module Helpers
    module ClassesHelper

      def notation_to_class_uri(submission)
        params ||= @params

        if params[:cls] && !params[:cls].start_with?("http")
          f = Goo::Filter.new(:notation) == params[:cls]
          notation_lookup = LinkedData::Models::Class.where.filter(f).in(submission).first

          if notation_lookup
            cls_uri = notation_lookup.id
            return cls_uri
          end
          f = Goo::Filter.new(:prefixIRI) == params[:cls]
          prefix_lookup = LinkedData::Models::Class.where.filter(f).in(submission).first

          if prefix_lookup
            cls_uri = prefix_lookup.id
            return cls_uri
          end
        end
        return nil
      end

      def get_class(submission, load_attrs=nil)
        load_attrs = load_attrs || LinkedData::Models::Class.goo_attrs_to_load(includes_param)
        load_children = load_attrs.delete :children

        if !load_children
          load_children = load_attrs.select { |x| x.instance_of?(Hash) && x.include?(:children) }

          if load_children
            load_attrs = load_attrs.select { |x| !(x.instance_of?(Hash) && x.include?(:children)) }
          end
        end

        cls_uri = notation_to_class_uri(submission)

        if cls_uri.nil?
          cls_uri = RDF::URI.new(params[:cls])

          if !cls_uri.valid?
            error 400, "The input class id '#{params[:cls]}' is not a valid IRI"
          end
        end
        aggregates = LinkedData::Models::Class.goo_aggregates_to_load(load_attrs)
        cls = LinkedData::Models::Class.find(cls_uri).in(submission)
        cls = cls.include(load_attrs) if load_attrs && load_attrs.length > 0
        cls.aggregate(*aggregates) unless aggregates.empty?
        cls = cls.first

        if cls.nil?
          error 404,
                "Resource '#{params[:cls]}' not found in ontology #{submission.ontology.acronym} submission #{submission.submissionId}"
        end

        if load_children
          LinkedData::Models::Class.partially_load_children([cls],500,cls.submission)
        end
        return cls
      end

      ALLOWED_INCLUDES_PARAMS_SOLR_POPULATION = [:prefLabel, :synonym, :definition].freeze
      def validate_params_solr_population
        leftover = includes_param - ALLOWED_INCLUDES_PARAMS_SOLR_POPULATION
        invalid = leftover.length > 0
        message = "The `include` query string parameter cannot accept #{leftover.join(", ")}, please use only #{ALLOWED_INCLUDES_PARAMS_SOLR_POPULATION.join(", ")}"
        error 400, message if invalid
      end

    end
  end
end

helpers Sinatra::Helpers::ClassesHelper
