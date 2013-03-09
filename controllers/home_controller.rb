class HomeController
  namespace "/" do

    get do
      routes = routes_list
      routes_hash = {}
      routes.each do |route|
        next if route.length < 3 || route.split("/").length > 2
        routes_hash[route.gsub("/", "")] = $REST_URL_PREFIX+route
      end
      reply ({links: routes_hash})
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
  %link{href: "http://twitter.github.com/bootstrap/assets/js/google-code-prettify/prettify.css", rel: "stylesheet", media: "screen"}
  %link{href: "//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/css/bootstrap-combined.min.css", rel: "stylesheet", media: "screen"}
  :css
    body {
      max-width: 1040px;
      margin: 3em;
    }
    table, th, td {
      vertical-align: top;
    }
    td, th { padding: 5px; }
    th {
      text-align: left;
      font-weight: bold;
    }
    h2 { margin-top: 1em; }
    .collection_link {
      font-size: larger;
      padding: 0 0 .5em;
    }
    .resource {
      margin: 0 2em 2.5em 3em;
    }
%body
  %script{src: "//cdnjs.cloudflare.com/ajax/libs/jquery/1.9.1/jquery.min.js"}
  %script{src: "//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/js/bootstrap.min.js"}
  %script{src: "http://twitter.github.com/bootstrap/assets/js/google-code-prettify/prettify.js"}
  = yield
  :javascript
    // @prettify
    !function ($) {
      $(function(){
      window.prettyPrint && prettyPrint()
      })
    }(window.jQuery);
    // #prettify
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
:markdown
  #### JSON
  The default content type is JSON, specifically a variant called [JSON-LD](http://json-ld.org/),
  or JSON Linked Data. You can treat this variant like normal JSON. All JSON parsers will be able
  to parse the output normally. The benefit of JSON-LD is that it enables hypermedia links, and you
  will find these links exposed as URLs in attributes labeled `@id`, which correspond to the id of the
  parent resource, or in an array called `links`, which contains a hash of link types with corresponding URLs.

  Here is a sample output of the JSON response format:
  <pre class="prettyprint linenums lang-javascript" style="display: table; padding-right: 20px;">
  {
      "administeredBy": [
          "http://data.bioontology.org/user/nevada"
      ],
      "acronym": "ABA-API-TST",
      "name": "ABA Adult Mouse Brain",
      "@id": "http://data.bioontology.org/ontology/ABA-API-TST",
      "@type": "http://data.bioontology.org/metadata/Ontology",
      "links": {
          "metrics": "http://data.bioontology.org/ontologies/ABA-API-TST/metrics",
          "submissions": "http://data.bioontology.org/ontologies/ABA-API-TST/submissions",
          "classes": "http://data.bioontology.org/ontologies/ABA-API-TST/classes",
          "roots": "http://data.bioontology.org/ontologies/ABA-API-TST/classes/roots",
          "reviews": "http://data.bioontology.org/ontologies/ABA-API-TST/reviews"
      },
      "@context": {
          "@vocab": "http://data.bioontology.org/metadata/",
          "acronym": "http://omv.ontoware.org/2005/05/ontology#acronym",
          "name": "http://omv.ontoware.org/2005/05/ontology#name",
          "administeredBy": {
              "@id": "http://data.bioontology.org/metadata/User",
              "@type": "@id"
          }
      }
  }
  </pre>

  - Line 7 shows the id for the resource. Doing an HTTP GET on the id will retreive the resource.
  - Line 8 shows the media type (see below).
  - Line 9 starts the links hash.
  - Line 16 is the resource's context, which can be used to determine the type for lists of ids. For example, line 2 lists
    the ids for users who administer the ontology, which can be determined by looking for the `administeredBy` attribute
    in the `@context` hash.
  - If you are interested in the predicate URI values used in the resource, these can be deterined by looking up the
    attribute in the `@context` hash or by appending the value of `@vocab` (line 17) to an attribute name in cases where
    the attribute isn't listed specifically in the `@context`.

  #### XML
  XML is also available as an alternative content type.

%p Here is sample output for the XML format:
<pre class="prettyprint linenums lang-xml" style="display: table; padding-right: 20px;">
:escaped
  <ontology>
    <administeredByCollection>
      <administeredBy>http://data.bioontology.org/user/nevada</administeredBy>
    </administeredByCollection>
    <acronym>ABA-API-TST</acronym>
    <name>ABA Adult Mouse Brain</name>
    <id>http://data.bioontology.org/ontology/ABA-API-TST</id>
    <links>
      <self href="http://data.bioontology.org/ontology/ABA-API-TST" rel="http://data.bioontology.org/metadata/Ontology"/>
      <metrics href="/ontologies/ABA-API-TST/metrics"/>
      <submissions href="/ontologies/ABA-API-TST/submissions" rel="http://data.bioontology.org/metadata/OntologySubmission"/>
      <classes href="/ontologies/ABA-API-TST/classes" rel="http://www.w3.org/2002/07/owl#Class"/>
      <roots href="/ontologies/ABA-API-TST/classes/roots" rel="http://www.w3.org/2002/07/owl#Class"/>
      <reviews href="/ontologies/ABA-API-TST/reviews" rel="http://data.bioontology.org/metadata/Review"/>
    </links>
  </ontology>
</pre>

%h2 Media Types

%h3 Documentation
:markdown
  The documentation below describes the media types that available in the API. Media types describe the types of
  resources available, including the HTTP verbs that may be used with them and the attributes that each resource
  contains.

  #### HTTP Verbs
  The API uses different verbs to support processing of resources. This includes things like creating or deleting
  individual resources or something more specific like parsing an ontology. Typically, the verbs will be used

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
-routes = routes_by_class[@metadata[:cls]]
-return "" if routes.nil? || routes.empty?
%h3.text-success{id: @metadata[:cls].name.split("::").last}= @metadata[:uri]
%div.resource
  %div.collection_link
    -link = resource_collection_link(@metadata[:cls])
    -if link && !link.eql?("")
      =resource_collection_link(@metadata[:cls])
    -else
      Sample Link: coming soon
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
      return @metadata_all_info if @metadata_all_info
      ld_classes = ObjectSpace.each_object(Class).select { |klass| klass < LinkedData::Models::Base }
      info = {}
      ld_classes.each do |cls|
        next if routes_by_class[cls].nil? || routes_by_class[cls].empty?
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

        info[cls] = cls_info
      end

      # Sort by 'shown by default'
      info.each do |cls, cls_props|
        shown = {}
        not_shown = {}
        cls_props[:attributes].each {|attr,values| values[:shows_default] ? shown[attr] = values : not_shown[attr] = values}
        cls_props[:attributes] = shown.merge(not_shown)
      end

      @metadata_all_info = info
      info
    end

    def hypermedia_links(cls)
      cls.hypermedia_settings[:link_to]
    end

    def routes_by_class
      return @routes_by_class if @routes_by_class
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
      @routes_by_class = routes_by_class
      routes_by_class
    end

    def routes_list
      return @navigable_routes if @navigable_routes
      routes = Sinatra::Application.routes["GET"]
      navigable_routes = []
      Sinatra::Application.each_route do |route|
        if route.verb.eql?("GET") && route[1].empty?
          navigable_routes << route.path
        end
      end
      @navigable_routes = navigable_routes
      navigable_routes
    end

  end
end

