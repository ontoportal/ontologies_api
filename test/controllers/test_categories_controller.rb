require_relative '../test_case'
require "multi_json"

class TestCategoriesController < TestCase

  def setup
    # Create some test categories
    @test_cat = {acronym: "TEST-CAT", name: "Test Category", description: "Description of the Test Category"}

    @cats = {
        "ANAT" => ["Anatomy", "Anatomy Category Description"],
        "ANIMAL-DEV" => ["Animal Development", "Animal Development Category Description"],
        "AGA" => ["Animal Gross Anatomy", "Description for Animal Gross Anatomy"],
        "ARABADOPSIS" => ["Arabadopsis", "Arabadopsis Category Description"],
        "BP" => ["Biological Process", "Biological Process Category Description"],
        "BR" => ["Biomedical Resources", "Description of Biomedical Resources Category"],
        "CELL" => ["Cell", "Cell Category Description"]
    }

    # Make sure these don't exist
    _delete_categories

    i = 0
    # Create them again
    @cats.each do |acronym, name_desc|
      category = Category.new(acronym: acronym, name: name_desc[0], description: name_desc[1])
      category.save if category.valid?
      i += 1
    end
  end

  def teardown
    # Delete groups
    _delete_categories
  end

  def _delete_categories
    test_cat = Category.find(@test_cat[:acronym]).first
    test_cat.delete unless test_cat.nil?

    @cats.each do |acronym, name_desc|
      cat = Category.find(acronym).first
      cat.delete unless cat.nil?
      assert Category.find(acronym).nil?
    end
  end

  def test_all_categories
    get '/categories'
    assert last_response.ok?

    categories = MultiJson.load(last_response.body)
    all_acronyms = []
    categories.each do |returned_cat|
      all_acronyms << returned_cat["acronym"]
    end

    @cats.each do |acronym, name_desc|
      assert all_acronyms.include?(acronym)
    end
  end

  def test_single_category
    @cats.each do |acronym, name_desc|
      get "/categories/#{acronym}"
      assert last_response.ok?
      category = MultiJson.load(last_response.body)
      assert_equal acronym, category["acronym"]
    end
  end

  def test_create_new_category
    acronym = @test_cat[:acronym]
    put "/categories/#{acronym}", MultiJson.dump(@test_cat), "CONTENT_TYPE" => "application/json"

    assert last_response.status == 201
    assert MultiJson.load(last_response.body)["acronym"].eql?(acronym)

    get "/categories/#{acronym}"
    assert last_response.ok?
    assert MultiJson.load(last_response.body)["acronym"].eql?(acronym)

    delete "/categories/#{acronym}"

    post "/categories", MultiJson.dump(@test_cat), "CONTENT_TYPE" => "application/json"

    assert last_response.status == 201
    assert MultiJson.load(last_response.body)["acronym"].eql?(acronym)

    get "/categories/#{acronym}"
    assert last_response.ok?
    assert MultiJson.load(last_response.body)["acronym"].eql?(acronym)
  end

  def test_update_patch_category
    acronym = 'ANAT'
    category = Category.find(acronym).first
    assert_instance_of Category, category
    new_name = "Anatomyzation new NAME"
    new_desc = "Anatomyzation new DESCRIPTION"
    new_values = {name: new_name, description: new_desc}

    patch "/categories/#{acronym}", MultiJson.dump(new_values), "CONTENT_TYPE" => "application/json"
    assert last_response.status == 204

    get "/categories/#{acronym}"
    group = MultiJson.load(last_response.body)
    assert group["name"].eql?(new_name)
    assert group["description"].eql?(new_desc)
  end

  def test_delete_category
    acronym = 'ANAT'
    delete "/categories/#{acronym}"
    assert last_response.status == 204

    get "/categories/#{acronym}"
    assert last_response.status == 404
  end
end