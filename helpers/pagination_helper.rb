require 'sinatra/base'

module Sinatra
  module Helpers
    module PaginationHelper
      ##
      # Check the request params to get page and pagesize, both are returned
      def page_params
        page = @params["page"]     || 1
        size = @params["pagesize"] || 50
        begin
          page = Integer(page)
          size = Integer(size)
        rescue
          error 400, "Page number and page size must be integers. Page number is #{page} and page size is #{size}."
        end
        raise error 400, "Limit page size is 500. Page size in request is #{size}" if size > 500
        return page, size
      end

      ##
      # Calculate the offset and limit based on page and pagesize, both are returned
      def offset_and_limit(page, pagesize)
        offset = page * pagesize - pagesize
        return offset, limit
      end

      ##
      # Return a page object given the total potential results for a call and an array
      def page_object(array, total_result_count = nil)
        page, size = page_params
        page_count = (total_result_count.to_f / size.to_f).ceil unless total_result_count.nil?
        page_count ||= 0
        page_obj = LinkedData::Models::Page.new(page, page+1, page_count, array)
        page_obj.totalResults = total_result_count
        page_obj
      end
    end
  end
end

helpers Sinatra::Helpers::PaginationHelper
