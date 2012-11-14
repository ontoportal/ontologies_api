require_relative '../test_case'

class TestProvisionalClassesController < TestCase
  def test_all_provisional_classes
    get '/provisional_classes'
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_single_provisional_class
    provisional_class = 'test_provisional_class'
    get "/provisional_classes/#{provisional_class}"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_create_new_provisional_class
  end

  def test_update_replace_provisional_class
  end

  def test_update_patch_provisional_class
  end

  def test_delete_provisional_class
  end

end