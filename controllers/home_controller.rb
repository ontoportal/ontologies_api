class HomeController
  namespace "/" do

    get do
      reply routes_list
    end

    get "documentation" do
      @metadata_all = metadata_all.sort {|a,b| a[0].name <=> b[0].name}
      haml :documentation
    end

    get "metadata/:class" do
      @metadata = metadata(params["class"])
      haml :metadata
    end

    template :layout do
      <<-EOS
%html
%head
  %meta{name: "viewport", content: "width=device-width, initial-scale=1.0"}
  %link{href: "//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/css/bootstrap-combined.min.css", rel: "stylesheet", media: "screen"}
  :css
    body { margin: 3em; }
    table, th, td {
      max-width: 1040px;
      vertical-align: top;
    }
    td, th { padding: 5px; }
    th {
      text-align: left;
      font-weight: bold;
    }
    h2 { margin-top: 1.5em; }
    .collection_link {
      font-size: larger;
      padding: 0 0 .5em;
    }
    .resource { margin-bottom: 2.5em; }
%body
  = yield
      EOS
    end

    template :documentation do
      <<-EOS
%h1 API Documentation
%h2 General Usage
%p
  This API uses hypermedia to expose relationships between media types. The state of the application
  is driven by navigating these links.
%h3 Common Parameters
%table.table.table-striped.table-bordered
  %tr
    %th Parameter
    %th Possible Values
    %th Description
  %tr
    %td include
    %td
      all<br/>
      {comma-separated list of attributes, EX: attr1,attr2}
    %td
      By default, the API will show a subset of the available attributes for a given media type.
      This behavior can be overridden by providing <code>include=all</code> to show all attributes
      or <code>include=attribute1,attribute2</code> to include a specific list. The API is optimized
      to return the default values, so overriding this can impact the performance of your request.
  %tr
    %td format
    %td
      json<br/>
      jsonp<br/>
      xml
    %td
      The API returns JSON as the default content type. This can be overridden by using the <code>format</code>
      query string parameter. The API also respects <code>Accept</code> header entries, with precedence given
      to the <code>format</code> parameter.

%h2 Content Types
%p
:markdown
  #### JSON
  The default content type is JSON, specifically a variant called [JSON-LD](http://json-ld.org/)
  , or JSON Linked Data. You can treat this variant like normal JSON. All JSON parsers will be able
  to parse the output normally. The benefit of JSON-LD is that it enables hypermedia links, and you
  will find these in attributes labeled `@id`.

  #### XML
  XML is also available as an alternative content type.

%h2 Media Types
%ol
  -@metadata_all.each do |cls|
    %li
      %a{href: "#" + cls[1][:cls].name.split("::").last}= cls[1][:uri]
-@metadata_all.each do |cls, type|
  -@metadata = type
  =render(:haml, :metadata)
      EOS
    end

    template :metadata do
      <<-EOS
%h3{id: @metadata[:cls].name.split("::").last}= @metadata[:uri]
%div.collection_link
  =resource_collection_link(@metadata[:cls])
%div.resource
  -routes = routes_by_class[@metadata[:cls]]
  -if routes
    %h4 HTTP Methods for Resource
    %table.table.table-striped.table-bordered
      %tr
        %th HTTP Verb
        %th Path
      -routes.each do |route|
        %tr
          %td= route[0]
          %td= route[1]

  %h4 Resource Description
  %table.table.table-striped.table-bordered
    %tr
      %th Attribute
      %th Default
      %th Unique
      %th Cardinality
      %th Type
    -@metadata[:attributes].each do |attr, values|
      %tr
        %td= attr.to_s
        %td= values[:shows_default]
        %td= values[:unique]
        %td= values[:cardinality]
        %td= values[:type].to_s + "&nbsp;"
  -links = hypermedia_links(@metadata[:cls])
  -if links && !links.empty?
    %h4 Related Hypermedia Links
    %table.table.table-striped.table-bordered
      %tr
        %th Type
        %th Path
      -hypermedia_links(@metadata[:cls]).each do |link|
        %tr
          %td= link.type
          %td= link.path
      EOS
    end

    def resource_collection_link(cls)
      resource = @metadata[:cls].name.split("::").last
      return "" if resource.nil?
      resource_path = "/" + resource.downcase.pluralize
      return "" unless routes_list.include?(resource_path)
      return "Resource collection: <a href='#{resource_path}'>#{resource_path}</a>"
    end

    def metadata(cls)
      cls = LinkedData::Models.const_get(cls) unless cls.is_a?(Class)
      metadata_all[cls]
    end

    def metadata_all
      ld_classes = ObjectSpace.each_object(Class).select { |klass| klass < LinkedData::Models::Base }
      info = {}
      ld_classes.each do |cls|
        attributes = cls.defined_attributes_not_transient
        attributes_info = {}
        attributes.each do |attribute|
          next if cls.hypermedia_settings[:serialize_never].include?(attribute)

          schema = cls.goop_settings[:attributes][attribute][:validators]
          if schema[:instance_of]
            model = schema[:instance_of][:with]
            model_cls = Goo.find_model_by_name(model)
            type = model_cls.type_uri if model_cls.respond_to?("type_uri")
          elsif schema[:instance_of] && !schema[:instance_of][:date_time_xsd].nil?
            type = "xsd:dateTime"
          else
            type = ""
          end

          shows_default = cls.hypermedia_settings[:serialize_default].empty? ? true : cls.hypermedia_settings[:serialize_default].include?(attribute)

          attributes_info[attribute] = {
            type: type || "",
            shows_default: shows_default,
            unique: !schema[:unique].nil?,
            cardinality: schema[:cardinality] || {min: 0}
          }
        end

        cls_info = {
          attributes: attributes_info,
          uri: cls.type_uri,
          cls: cls
        }

        # Merge Ontology and OntologySubmission
        if cls == LinkedData::Models::OntologySubmission || cls == LinkedData::Models::Ontology
          ont = info[LinkedData::Models::Ontology] ||= {}
          attributes = ont[:attributes] || {}
          info[LinkedData::Models::Ontology][:attributes] = attributes.merge(cls_info[:attributes])
          if cls == LinkedData::Models::Ontology
            cls_info.delete(:attributes)
            info[cls].merge!(cls_info)
          end
        else
          info[cls] = cls_info
        end
      end

      # Sort by 'shown by default'
      info.each do |cls, cls_props|
        shown = {}
        not_shown = {}
        cls_props[:attributes].each {|attr,values| values[:shows_default] ? shown[attr] = values : not_shown[attr] = values}
        cls_props[:attributes] = shown.merge(not_shown)
      end

      info
    end

    def hypermedia_links(cls)
      cls.hypermedia_settings[:link_to]
    end

    def routes_by_class
      all_routes = Sinatra::Application.routes
      routes_by_file = {}
      all_routes.each do |method, routes|
        routes.each do |route|
          routes_by_file[route.file] ||= []
          routes_by_file[route.file] << route
        end
      end
      routes_by_class = {}
      routes_by_file.each do |file, routes|
        cls_name = file.split("/").last.gsub(".rb", "").classify.gsub("Controller", "").singularize
        cls = LinkedData::Models.const_get(cls_name) rescue nil
        next if cls.nil?
        routes.each do |route|
          next if route.verb == "HEAD"
          routes_by_class[cls] ||= []
          routes_by_class[cls] << [route.verb, route.path]
        end
      end
      routes_by_class
    end

    def routes_list
      routes = Sinatra::Application.routes["GET"]
      navigable_routes = []
      Sinatra::Application.each_route do |route|
        if route.verb.eql?("GET") && route[1].empty?
          navigable_routes << route.path
        end
      end
      navigable_routes
    end

  end
end

