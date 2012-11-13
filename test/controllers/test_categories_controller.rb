require_relative '../test_case'

class TestcategoriesController < TestCase
  def test_all_categories
    get '/categories'
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_single_category
    category = 'test_category'
    get "/categories/#{category}"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_create_new_category
  end

  def test_update_replace_category
  end

  def test_update_patch_category
  end

  def test_delete_category
  end

end