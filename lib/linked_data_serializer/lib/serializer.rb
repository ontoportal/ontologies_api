require_relative "media_types"
require_relative "serializers"

module LinkedData
  class Serializer
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, response = @app.call(env)
      params = env["rack.request.query_hash"]
      # Client accept header
      accept = env['rack-accept.request']
      # Out of the media types we offer, which would be best?
      best = LinkedData::MediaTypes.base_type(accept.best_media_type(LinkedData::MediaTypes.all))
      # If user provided a format via query string, override the accept header
      best = params["format"].to_sym if params["format"]
      # Error out if we don't support the foramt
      unless LinkedData::MediaTypes.supported_base_type?(best)
        return response(:status => 415)
      end
      begin
        response(
          :status => status,
          :content_type => "#{LinkedData::MediaTypes.media_type_from_base(best)};charset=utf-8",
          :body => serialize(best, response, params)
        )
      rescue Exception => e
        message = e.message + "\n\n" + e.backtrace.join("\n") if development?
        response(:status => 500, :body => message)
      end
    end

    private

    def response(options = {})
      status = options[:status] ||= 200
      headers = options[:headers] ||= {}
      body = options[:body] ||= ""
      content_type = options[:content_type] ||= "text/plain"
      content_length = options[:content_length] ||= body.bytesize.to_s
      raise ArgumentError("Body must be a string") unless body.kind_of?(String)
      headers.merge!({"Content-Type" => content_type, "Content-Length" => content_length})
      [status, headers, body]
    end

    def serialize(type, obj, params)
      only = params["include"] ||= []
      only = only.split(",") unless only.kind_of?(Array)
      only, all = [], true if only[0].eql?("all")
      options = {:only => only, :all => all}
      LOGGER.debug options
      LinkedData::Serializers.serialize(obj, type, options)
    end

    def serialize_json(obj, options = {})
      obj.to_flex_hash(options).to_json
    end

    def serialize_html(obj, options = {})
      "html"
    end

    def serialize_xml(obj, options = {})
      "xml"
    end

    def serialize_turtle(obj, options = {})
      "turtle"
    end

  end
end