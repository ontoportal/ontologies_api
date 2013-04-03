require 'haml'

class HomeController
  namespace "/" do

    get do
      routes = routes_list
      routes_hash = {}
      context = {}
      routes.each do |route|
        next if route.length < 3 || route.split("/").length > 2
        route_no_slash = route.gsub("/", "")
        context[route_no_slash] = route_to_class_map[route].type_uri if route_to_class_map[route]
        routes_hash[route_no_slash] = LinkedData.settings.rest_url_prefix+route_no_slash
      end
      routes_hash["@context"] = context
      reply ({links: routes_hash})
    end

    get "documentation" do
      @metadata_all = metadata_all.sort {|a,b| a[0].name <=> b[0].name}
      haml "documentation/documentation".to_sym, :layout => "documentation/layout".to_sym
    end

    get "metadata/:class" do
      @metadata = metadata(params["class"])
      haml "documentation/metadata".to_sym, :layout => "documentation/layout".to_sym
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

    def route_to_class_map
      return @route_to_class_map if @route_to_class_map
      map = {}
      routes_by_class.each do |cls, routes|
        routes.each do |route|
          map[route[1]] = cls
        end
      end
      @route_to_class_map = map
      map
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

