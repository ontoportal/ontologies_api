require "rack/test"
require_relative "../test_case"

OUTER_APP = Rack::Builder.parse_file(File.join([settings.root, "config.ru"])).first

class TestRackAttackV2 < TestCase
  include Rack::Test::Methods

  def app
    OUTER_APP
  end

  def self.before_suite
    # Store app settings
    @@enable_security = LinkedData.settings.enable_security
    @@enable_throttling = LinkedData::OntologiesAPI.settings.enable_throttling
    @@limit = LinkedData::OntologiesAPI.settings.req_per_second_per_ip
    @@safe_ips = LinkedData::OntologiesAPI.settings.safe_ips

    LinkedData.settings.enable_security = true
    LinkedData::OntologiesAPI.settings.enable_throttling = true
    LinkedData::OntologiesAPI.settings.req_per_second_per_ip = 5
    LinkedData::OntologiesAPI.settings.safe_ips = Set.new(["1.2.3.4", "1.2.3.5"])
    require_relative "../../config/rack_attack"

    @@user = LinkedData::Models::User.new({
      username: "user",
      password: "test_password",
      email: "test_email@example.org"
    })
    @@user.save
  
    admin_role = LinkedData::Models::Users::Role.find("ADMINISTRATOR").first
    @@admin = LinkedData::Models::User.new({
      username: "admin",
      password: "test_password",
      email: "test_email@example.org",
      role: [admin_role]
    })
    @@admin.save

    @@ncbobioportal_user = LinkedData::Models::User.new({
      username: "ncbobioportal",
      password: "test_password",
      email: "test_email@example.org"
    })
    @@ncbobioportal_user.save
    
    @@biomixer_user = LinkedData::Models::User.new({
      username: "biomixer",
      password: "test_password",
      email: "test_email@example.org",
    })
    @@biomixer_user.save
  end

  def test_throttling_exceed_limit
    statuses = Set.new
    (LinkedData::OntologiesAPI.settings.req_per_second_per_ip * 5).times do |i|
      header "Authorization", "apikey token=#{@@user.apikey}"
      get "/", {}, "REMOTE_ADDR" => "1.2.3.6"
      statuses << last_response.status
    end
    assert_includes statuses, 429, "Failed to throttle excessive requests"
  end

  def test_throttling_under_limit
    LinkedData::OntologiesAPI.settings.req_per_second_per_ip.times do
      header "Authorization", "apikey token=#{@@user.apikey}"
      get "/", {}, "REMOTE_ADDR" => "1.2.3.7"
      assert last_response.status != 429, "Requests under the reqs/sec limit were throttled"
    end
  end

  def test_throttling_admin_override
    (LinkedData::OntologiesAPI.settings.req_per_second_per_ip * 5).times do |i|
      header "Authorization", "apikey token=#{@@admin.apikey}"
      get "/", {}, "REMOTE_ADDR" => "1.2.3.8"
      assert last_response.status != 429, "Requests from an administrative account were throttled"
    end
  end

  def test_throttling_ncbobioportal_override
    (LinkedData::OntologiesAPI.settings.req_per_second_per_ip * 5).times do |i|
      header "Authorization", "apikey token=#{@@ncbobioportal_user.apikey}"
      get "/", {}, "REMOTE_ADDR" => "1.2.3.9"
      assert last_response.status != 429, "Requests from the ncbobioportal account were throttled"
    end
  end

  def test_throttling_biomixer_override
    (LinkedData::OntologiesAPI.settings.req_per_second_per_ip * 5).times do |i|
      header "Authorization", "apikey token=#{@@biomixer_user.apikey}"
      get "/", {}, "REMOTE_ADDR" => "1.2.3.10"
      assert last_response.status != 429, "Requests from the biomixer account were throttled"
    end
  end

  def test_throttling_safe_ip_override
    safe_ips = LinkedData::OntologiesAPI.settings.safe_ips
    limit = LinkedData::OntologiesAPI.settings.req_per_second_per_ip

    safe_ips.each do |safe_ip|
      (limit * 5).times do |i|
        header "Authorization", "apikey token=#{@@user.apikey}"
        get "/", {}, "REMOTE_ADDR" => safe_ip
        assert last_response.status != 429, "Requests from a safelisted IP address were throttled"
      end
    end
  end

  def self.after_suite
    # Restore app settings
    LinkedData.settings.enable_security = @@enable_security
    LinkedData::OntologiesAPI.settings.enable_throttling = @@enable_throttling
    LinkedData::OntologiesAPI.settings.req_per_second_per_ip = @@limit
    LinkedData::OntologiesAPI.settings.safe_ips = @@safe_ips
    
    @@user.delete
    @@admin.delete
    @@ncbobioportal_user.delete
    @@biomixer_user.delete
  end
end
