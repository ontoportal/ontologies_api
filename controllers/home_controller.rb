class HomeController
  namespace "/" do

    get do
      reply list_routes
    end

    def list_routes
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