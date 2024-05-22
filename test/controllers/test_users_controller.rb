require_relative '../test_case'

class TestUsersController < TestCase
  def self.before_suite
    # Create a bunch of test users
    @@usernames = %w(fred goerge henry ben mark matt charlie)

    # Create them again
    @@users = @@usernames.map do |username|
      User.new(username: username, email: "#{username}@example.org", password: "pass_word").save
    end

    # Test data
    @@username = "test_user"
  end

  def self._delete_users
    @@usernames.each do |username|
      user = User.find(username).first
      user.delete unless user.nil?
    end
  end

  def test_admin_creation
    existent_user = @@users.first #no admin

    refute _create_admin_user(apikey: existent_user.apikey), "A no admin user can't create an admin user or update it to an admin"

    existent_user = self.class.make_admin(existent_user)
    assert _create_admin_user(apikey: existent_user.apikey), "Admin can create an admin user or update it to be an admin"
    self.class.reset_to_not_admin(existent_user)
    delete "/users/#{@@username}"
  end

  def test_all_users
    get '/users'
    assert last_response.ok?
    users = MultiJson.load(last_response.body)
    assert users.any? {|u| u["username"].eql?("fred")}
    assert users.length >= @@usernames.length
  end

  def test_single_user
    user = 'fred'
    get "/users/#{user}"
    assert last_response.ok?

    assert_equal "fred", MultiJson.load(last_response.body)["username"]
  end

  def test_create_new_user
    user = {email: "#{@@username}@example.org", password: "pass_the_word"}
    put "/users/#{@@username}", MultiJson.dump(user), "CONTENT_TYPE" => "application/json"
    assert last_response.status == 201
    created_user = MultiJson.load(last_response.body)
    assert created_user["username"].eql?(@@username)

    get "/users/#{@@username}"
    assert last_response.ok?
    assert MultiJson.load(last_response.body)["username"].eql?(@@username)

    delete created_user["@id"]
    post "/users", MultiJson.dump(user.merge(username: @@username)), "CONTENT_TYPE" => "application/json"
    assert last_response.status == 201
    assert MultiJson.load(last_response.body)["username"].eql?(@@username)

    get "/users/#{@@username}"
    assert last_response.ok?
    assert MultiJson.load(last_response.body)["username"].eql?(@@username)
  end

  def test_create_new_invalid_user
    put "/users/totally_new_user"
    assert last_response.status == 422
  end

  def test_no_duplicate_user
    put "/users/fred"
    assert last_response.status == 409
  end

  def test_update_patch_user
    add_first_name = {firstName: "Fred"}
    patch "/users/fred", MultiJson.dump(add_first_name), "CONTENT_TYPE" => "application/json"
    assert last_response.status == 204

    get "/users/fred?include=all"
    fred = MultiJson.load(last_response.body)
    assert fred["firstName"].eql?("Fred")
  end

  def test_delete_user
    delete "/users/ben"
    assert last_response.status == 204

    @@usernames.delete("ben")

    get "/users/ben"
    assert last_response.status == 404
  end

  def test_user_not_found
    get "/users/this_user_definitely_does_not_exist"
    assert last_response.status == 404
  end

  def test_authentication
    post "/users/authenticate", {user: @@usernames.first, password: "pass_word"}
    assert last_response.ok?
    user = MultiJson.load(last_response.body)
    assert user["username"].eql?(@@usernames.first)
  end

  def test_oauth_authentication
    fake_responses = {
      github: {
        id: 123456789,
        login: 'github_user',
        email: 'github_user@example.com',
        name: 'GitHub User',
        avatar_url: 'https://avatars.githubusercontent.com/u/123456789'
      },
      google: {
        sub: 'google_user_id',
        email: 'google_user@example.com',
        name: 'Google User',
        given_name: 'Google',
        family_name: 'User',
        picture: 'https://lh3.googleusercontent.com/a-/user-profile-image-url'
      },
      orcid: {
        orcid: '0000-0002-1825-0097',
        email: 'orcid_user@example.com',
        name: {
          "family-name": 'ORCID',
          "given-names": 'User'
        }
      }
    }

    fake_responses.each do |provider, data|
      WebMock.stub_request(:get, LinkedData::Models::User.oauth_providers[provider][:link])
             .to_return(status: 200, body: data.to_json, headers: { 'Content-Type' => 'application/json' })
      post "/users/authenticate", {access_token:'jkooko', token_provider: provider.to_s}
      assert last_response.ok?
      user = MultiJson.load(last_response.body)
      assert data[:email], user["email"]
    end
  end

  private
  def _create_admin_user(apikey: nil)
    user = {email: "#{@@username}@example.org", password: "pass_the_word", role: ['ADMINISTRATOR']}
    LinkedData::Models::User.find(@@username).first&.delete

    put "/users/#{@@username}", MultiJson.dump(user), "CONTENT_TYPE" => "application/json", "Authorization" => "apikey token=#{apikey}"
    assert last_response.status == 201
    created_user = MultiJson.load(last_response.body)
    assert created_user["username"].eql?(@@username)

    get "/users/#{@@username}?apikey=#{apikey}"
    assert last_response.ok?
    user = MultiJson.load(last_response.body)
    assert user["username"].eql?(@@username)

    return true if user["role"].eql?(['ADMINISTRATOR'])

    patch "/users/#{@@username}", MultiJson.dump(role: ['ADMINISTRATOR']), "CONTENT_TYPE" => "application/json", "Authorization" => "apikey token=#{apikey}"
    assert last_response.status == 204

    get "/users/#{@@username}?apikey=#{apikey}"
    assert last_response.ok?
    user = MultiJson.load(last_response.body)
    assert user["username"].eql?(@@username)

    true if user["role"].eql?(['ADMINISTRATOR'])
  end
end
