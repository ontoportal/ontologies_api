require_relative '../test_case'

class TestProjectsController < TestCase
  def test_all_projects
    get '/projects'
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_single_project
    project = ''
    get "/projects/#{project}"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_create_new_project
  end

  def test_update_replace_project
  end

  def test_update_patch_project
  end

  def test_delete_project
  end

end