class CategoriesController
  namespace "/categories" do
    # Display all categories
    get do
        categories = Category.all
        reply categories
    end

    # Display a single category
    get '/:name' do
        category_id = params["category"]
        category = Category.find(name)
        error 404, "Category #{name} not found" if category.nil?
        reply 200, category
    end

    # Create a category with the given acronym
    put '/:name' do
        category = Category.find(name: params["name"])
        if category.nil?
            category = instance_from_paramas(Category, params)
        else
            error 400, "Category exists, please use HTTP PATCH to update"
        end

        if category.valid?
            category.save
        else
            error 400, category.errors
        end

        reply 201, category
    end

    # Update an existing submission of an category
    patch '/:name' do
        category = Category.find(name: params["name"])
        if !category.nil?
            category = instance_from_paramas(Category, params)
        else
            error 400, "Category does not exist, please create using HTTP PUT before modifying"
        end

        if category.valid?
            category.save
        else
            error 400, category.errors
        end

        halt 204
    end

    # Delete a category
    delete '/:name' do
        
    end

  end
end