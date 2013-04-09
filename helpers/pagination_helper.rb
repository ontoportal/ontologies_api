require 'sinatra/base'

module Sinatra
  module Helpers
    module PaginationHelper
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

      def page_object(total_result_count, array)
        page, size = page_params
        page_count = (total_result_count.to_f / size.to_f).ceil
        LinkedData::Models::Page.new(page, page+1, page_count, array)
      end
    end
  end
end

helpers Sinatra::Helpers::PaginationHelper
