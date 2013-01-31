require_relative '../test_case'
require "json"

class TestCategoriesController < TestCase

  def setup
    @category_ids = ["cat1", "cat2", "cat3"]
    @category_ids.each do |cat_id|
      category = Category.new(name: cat_id)
      category.save if category.valid?
      assert !Category.find(cat_id).nil?
    end
  end

  def teardown
    @category_ids.each do |cat_id|
      category = Category.find(cat_id)
      category.delete unless category.nil?
      assert Category.find(cat_id).nil?
    end
  end

  def test_all_categories
    get '/categories'
    assert last_response.ok?

    categories = JSON.parse(last_response.body)
    all_ids = []
    categories.each do |returned_cat|
      all_ids << returned_cat["name"]
    end

    @category_ids.each do |cat_id|
      assert all_ids.include?(cat_id)
    end
  end

  def test_single_category
    @category_ids.each do |cat_id|
      get "/categories/#{cat_id}"
      assert last_response.ok?
      category = JSON.parse(last_response.body)
      #puts last_response.body
      assert_equal cat_id, category["name"]
    end
  end

  def test_create_new_category
    cat_name = "cat1"
    put "categories/#{cat_name}"
    assert last_response.status == 201

    category = JSON.parse(last_response.body)
    assert_equal cat_name, category["name"]
    category.delete unless category.nil?
  end

  def test_update_replace_category
  end

  def test_update_patch_category
  end

  def test_delete_category
  end

end