require_relative '../test_case'

class TestgroupsController < TestCase
  def test_all_groups
    get '/groups'
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_single_group
    group = 'test_group'
    get "/groups/#{group}"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_create_new_group
  end

  def test_update_replace_group
  end

  def test_update_patch_group
  end

  def test_delete_group
  end

end