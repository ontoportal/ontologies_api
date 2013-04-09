class CategoriesController < ApplicationController
  namespace "/categories" do
    # Display all categories
    get do
      categories = Category.all(load_attrs: Category.goo_attrs_to_load)
      reply categories
    end

    # Display a single category
    get '/:acronym' do
      acronym = params["acronym"]
      category = Category.find(acronym)
      error 404, "Category #{acronym} not found" if category.nil?
      reply 200, category
    end

    # Create a category with the given acronym
    put '/:acronym' do
      acronym = params["acronym"]
      category = Category.find(acronym)

      if category.nil?
        category = instance_from_params(Category, params)
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

    # Update an existing submission of a category
    patch '/:acronym' do
      acronym = params["acronym"]
      category = Category.find(acronym)

      if category.nil?
        error 400, "Category does not exist, please create using HTTP PUT before modifying"
      else
        category.load unless category.loaded?
        populate_from_params(category, params)

        if category.valid?
          category.save
        else
          error 400, category.errors
        end
      end
      halt 204
    end

    # Delete a category
    delete '/:acronym' do
      category = Category.find(params["acronym"])
      category.load unless category.loaded?
      category.delete
      halt 204
    end
  end
end