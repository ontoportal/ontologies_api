require 'rack'
require 'open-uri'
require_relative '../test_case'
require_relative '../../config/rack_attack'

RACK_CONFIG = File.join([settings.root, "config.ru"])

class TestRackAttack < TestCase
  def self.before_suite
    @@throttling_setting = LinkedData.settings.enable_throttling
    @@auth_setting = LinkedData.settings.enable_security
    @@req_per_sec_limit = LinkedData::OntologiesAPI.settings.req_per_second_per_ip
    LinkedData::OntologiesAPI.settings.req_per_second_per_ip = 1
    LinkedData.settings.enable_security = true
    LinkedData.settings.enable_throttling = true

    admin_role = LinkedData::Models::Users::Role.find("ADMINISTRATOR").first
    @@user = LinkedData::Models::User.new({
                                            username: "user",
                                            password: "test_password",
                                            email: "test_email@example.org"
                                          })
    @@user.save
    @@admin = LinkedData::Models::User.new({
                                             username: "admin",
                                             password: "test_password",
                                             email: "test_email@example.org",
                                             role: [admin_role]
                                           })
    @@admin.save

    # Redirect output or we get a bunch of crap from Rack
    # It gets reset in the after_suite
    $stdout = File.open("/dev/null", "w")
    $stderr = File.open("/dev/null", "w")

    @@port1 = Random.rand(55000..65535) # http://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers#Dynamic.2C_private_or_ephemeral_ports
    @@thread1 = Thread.new do
      Rack::Server.start(
        config: RACK_CONFIG,
        Port: @@port1,
        AccessLog: []
      )
    end
    @@port2 = Random.rand(55000..65535) # http://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers#Dynamic.2C_private_or_ephemeral_ports
    @@thread2 = Thread.new do
      Rack::Server.start(
        config: RACK_CONFIG,
        Port: @@port2,
        AccessLog: []
      )
    end

    # Let the servers start
    sleep(5)
  end

  def self.after_suite
    LinkedData.settings.enable_security = @@auth_setting
    LinkedData.settings.enable_throttling = @@throttling_setting
    LinkedData::OntologiesAPI.settings.req_per_second_per_ip = @@req_per_sec_limit
    Thread.kill(@@thread1)
    Thread.kill(@@thread2)
    $stdout = STDOUT
    $stderr = STDERR
    @@admin.delete
    @@user.delete
  end

  def test_throttling_limit
    request_in_threads do
      assert_raises(OpenURI::HTTPError) {
        request()
      }
    end
  end

  def test_throttling_override
    request_in_threads do
      assert_raises(OpenURI::HTTPError) {
        request()
      }

      request(user: @@admin) do |r|
        assert r.status[0].to_i == 200
      end
    end
  end

  def test_two_servers_one_ip
    request_in_threads do
      assert_raises(OpenURI::HTTPError) {
        request(port: @@port2)
      }
    end
  end

  private

  def request(user: nil, port: nil)
    user ||= @@user
    port ||= @@port1
    headers = {"Authorization" => "apikey token=#{user.apikey}"}
    open("http://127.0.0.1:#{port}/ontologies", headers)
  end

  def request_in_threads(&block)
    thread_count = 10
    threads = []
    begin
      thread_count.times do
        threads << Thread.new do
          while true
            sleep(0.2)
            request() rescue next
          end
        end
      end

      sleep(0.5)

      yield
    ensure
      sleep(1)
      threads.each {|t| t.kill; t.join}
    end
  end
end