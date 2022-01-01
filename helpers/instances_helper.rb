require 'sinatra/base'

module Sinatra
  module Helpers
    module InstancesHelper
      def label_regex_filter
        (Goo::Filter.new(:label).regex(@params["search"])) if @params["search"] != nil
      end

      def filter_classes_by(class_uri)
        class_uri.nil? ? nil :{types: RDF::URI.new(class_uri.to_s)}
      end

      def get_order_by_from(params , default_sort = :label , default_order = :asc)
        {(params["sortby"] || default_sort).to_sym => params["order"] || default_order} unless params["sortby"].nil? || params["sortby"] == ""
      end

      def get_attributes_to_include(includes_param)
        ld = LinkedData::Models::Instance.goo_attrs_to_load(includes_param)
        ld.delete(:properties)
        ld
      end

      def bring_unmapped?(includes_param)
        (includes_param && includes_param.include?(:all))
      end

      def bring_unmapped_to(page_data, sub)
        LinkedData::Models::Instance.in(sub).models(page_data).include(:unmapped).all
      end

      def bring_unmapped_if_needed(includes_param , page_data , sub)
        if bring_unmapped?(includes_param) && page_data.length > 0
          bring_unmapped_to page_data , sub
        end
      end
    end
  end
end

helpers Sinatra::Helpers::InstancesHelper