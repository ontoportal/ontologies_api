require 'sinatra/base'

module Sinatra
  module Helpers
    module InstancesHelper

      # TODO: generalize this to all routes (maybe in application_helper)
      def settings_params(klass)
        page, size = page_params
        attributes = get_attributes_to_include(includes_param, klass)
        order_by = get_order_by_from(@params)
        bring_unmapped = bring_unmapped?(includes_param)
        filter_by_label = label_regex_filter

        [attributes, page, size, filter_by_label, order_by, bring_unmapped]
      end

      def is_set?(param)
        !param.nil? && param != ""
      end

      def label_regex_filter
        (Goo::Filter.new(:label).regex(@params["search"])) if is_set?(@params["search"])
      end

      def filter_classes_by(class_uri)
        class_uri.nil? ? nil :{types: RDF::URI.new(class_uri.to_s)}
      end

      def get_order_by_from(params, default_order = :asc)
        if is_set?(params['sortby'])
          orders = (params["order"] || default_order.to_s).split(',')
          out = params['sortby'].split(',').map.with_index  do |param, index|
            sort_order_item(param, orders[index] || default_order)
          end
          out.to_h
        end

      end

      def get_attributes_to_include(includes_param, klass)
        ld = klass.goo_attrs_to_load(includes_param)
        ld.delete(:properties)
        ld
      end

      def bring_unmapped?(includes_param)
        (includes_param && includes_param.include?(:all))
      end

      def bring_unmapped_to(page_data, sub, klass = LinkedData::Models::Instance)
        klass.in(sub).models(page_data).include(:unmapped).all
      end

      private
      def sort_order_item(param , order)
        [param.to_sym, order.to_sym]
      end
    end
  end
end

helpers Sinatra::Helpers::InstancesHelper