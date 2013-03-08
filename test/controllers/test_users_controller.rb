require_relative '../test_case'
require 'json'

class TestUsersController < TestCase
  def setup
    # Create a bunch of test users
    @usernames = %w(fred goerge henry ben mark matt charlie)

    # Make sure these don't exist
    _delete_users

    # Create them again
    @usernames.each do |username|
      User.new(username: username, email: "#{username}@example.org", password: "pass_word").save
    end

    # Test data
    @username = "test_user"
  end

  def teardown
    # Delete users
    _delete_users

    # Remove test user if exists
    test_user = User.find(@username)
    test_user.delete unless test_user.nil?
  end

  def _delete_users
    @usernames.each do |username|
      user = User.find(username)
      user.delete unless user.nil?
    end
  end

  def test_all_users
    get '/users'
    assert last_response.ok?
    users = JSON.parse(last_response.body)
    users.any? {|u| u[:username].eql?("fred")}
    assert users.length >= @usernames.length
  end

  def test_single_user
    user = 'fred'
    get "/users/#{user}"
    assert last_response.ok?

    assert_equal "fred", JSON.parse(last_response.body)["username"]
  end

  def test_create_new_user
    user = {email: "#{@username}@example.org", password: "pass_the_word"}
    put "/users/#{@username}", user.to_json, "CONTENT_TYPE" => "application/json"
    assert last_response.status == 201
    assert JSON.parse(last_response.body)["username"].eql?(@username)

    get "/users/#{@username}"
    assert last_response.ok?
    assert JSON.parse(last_response.body)["username"].eql?(@username)
  end

  def test_create_new_invalid_user
    put "/users/totally_new_user"
    assert last_response.status == 422
  end

  def test_no_duplicate_user
    put "/users/#{@usernames.shuffle.first}"
    assert last_response.status == 409
  end


  def test_update_patch_user
    add_first_name = {firstName: "Fred"}
    patch "/users/fred", add_first_name.to_json, "CONTENT_TYPE" => "application/json"
    assert last_response.status == 204

    get "/users/fred?include=all"
    fred = JSON.parse(last_response.body)
    assert fred["firstName"].eql?("Fred")
  end

  def test_delete_user
    delete "/users/fred"
    assert last_response.status == 204

    get "/users/fred"
    assert last_response.status == 404
  end

  def test_user_not_found
    get "/users/this_user_definitely_does_not_exist"
    assert last_response.status == 404
  end

end