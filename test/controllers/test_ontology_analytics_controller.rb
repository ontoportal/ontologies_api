require_relative '../test_case'

class TestOntologyAnalyticsController < TestCase
  ANALYTICS_DATA = {
    "NCIT" => {
      2013 => {
        1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 2850, 11 => 1631, 12 => 1323
      },
      2014 => {
        1 => 1004, 2 => 1302, 3 => 2183, 4 => 2191, 5 => 1005, 6 => 1046, 7 => 1261, 8 => 1329, 9 => 1100, 10 => 956, 11 => 1105, 12 => 893
      },
      2015 => {
        1 => 840, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 0, 11 => 0, 12 => 0
      }
    },
    "ONTOMA" => {
      2013 => {
        1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 6, 11 => 15, 12 => 0
      },
      2014 => {
        1 => 2, 2 => 0, 3 => 0, 4 => 2, 5 => 2, 6 => 0, 7 => 6, 8 => 8, 9 => 0, 10 => 0, 11 => 0, 12 => 2
      },
      2015 => {
        1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 0, 11 => 0, 12 => 0
      }
    },
    "CMPO" => {
      2013 => {
        1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 64, 11 => 75, 12 => 22
      },
      2014 => {
        1 => 15, 2 => 15, 3 => 19, 4 => 12, 5 => 13, 6 => 14, 7 => 22, 8 => 12, 9 => 36, 10 => 6, 11 => 8, 12 => 10
      },
      2015 => {
        1 => 7, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 0, 11 => 0, 12 => 0
      }
    },
    "AEO" => {
      2013 => {
        1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 129, 11 => 142, 12 => 70
      },
      2014 => {
        1 => 116, 2 => 93, 3 => 85, 4 => 132, 5 => 96, 6 => 137, 7 => 69, 8 => 158, 9 => 123, 10 => 221, 11 => 163, 12 => 43
      },
      2015 => {
        1 => 25, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 0, 11 => 0, 12 => 0
      }
    },
    "SNOMEDCT" => {
      2013 => {
        1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 20721, 11 => 22717, 12 => 18565
      },
      2014 => {
        1 => 17966, 2 => 17212, 3 => 20942, 4 => 20376, 5 => 21063, 6 => 18734, 7 => 18116, 8 => 18676, 9 => 15728, 10 => 16348, 11 => 13933, 12 => 9533
      },
      2015 => {
        1 => 9036, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 0, 11 => 0, 12 => 0
      }
    },
    "TST" => {
      2013 => {
          1 => 0, 2 => 0, 3 => 23, 4 => 0, 5 => 0, 6 => 0, 7 => 20, 8 => 0, 9 => 0, 10 => 234, 11 => 7654, 12 => 2311
      },
      2014 => {
          1 => 39383, 2 => 239, 3 => 40273, 4 => 3232, 5 => 2, 6 => 58734, 7 => 11236, 8 => 23, 9 => 867, 10 => 232, 11 => 1111, 12 => 8
      },
      2015 => {
          1 => 2000, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 0, 11 => 0, 12 => 0
      }
    }
  }

  def self.before_suite
    @@redis = Redis.new(:host => Annotator.settings.annotator_redis_host, :port => Annotator.settings.annotator_redis_port)
    db_size = @@redis.dbsize
    if db_size > MAX_TEST_REDIS_SIZE
      puts "   This test cannot be run because there #{db_size} redis entries (max #{MAX_TEST_REDIS_SIZE}). You are probably pointing to the wrong redis backend. "
      return
    end
    @@redis.set(LinkedData::Models::Ontology::ONTOLOGY_ANALYTICS_REDIS_FIELD, Marshal.dump(ANALYTICS_DATA))
    @@onts = {
        "NCIT" => "NCIT Ontology",
        "ONTOMA" => "ONTOMA Ontology",
        "CMPO" => "CMPO Ontology",
        "AEO" => "AEO Ontology",
        "SNOMEDCT" => "SNOMEDCT Ontology",
        "TST" => "TST Ontology"
    }
    _delete
    _create_user
    _create_onts
  end

  def teardown
    self.class._delete_onts
    self.class._create_onts
  end

  def self._create_user
    username = "tim"
    test_user = LinkedData::Models::User.new(username: username, email: "#{username}@example.org", password: "password")
    test_user.save if test_user.valid?
    @@user = test_user.valid? ? test_user : LinkedData::Models::User.find(username).first
  end

  def self._create_onts
    @@onts.each do |acronym, name|
      ont = LinkedData::Models::Ontology.new(acronym: acronym, name: name, administeredBy: [@@user])
      ont.save
    end
  end

  def self._delete_onts
    @@onts.each do |acronym, _|
      ont = LinkedData::Models::Ontology.find(acronym).first
      ont.delete unless ont.nil?
    end
  end

  def self._delete
    _delete_onts
    test_user = LinkedData::Models::User.find("tim").first
    test_user.delete unless test_user.nil?
  end

  def test_ontology_analytics
    get "/analytics?year=2014&month=14"
    assert_equal(400, last_response.status, msg=get_errors(last_response))

    get "/analytics?year=20142&month=3"
    assert_equal(400, last_response.status, msg=get_errors(last_response))

    get "/analytics?ontologies=NCIT,ONTOMA"
    assert last_response.ok?
    analytics = MultiJson.load(last_response.body)
    assert_equal 2, analytics.length

    get "/analytics?ontologies=NCIT,ONTOMA&month=2"
    assert last_response.ok?
    analytics = MultiJson.load(last_response.body)
    analytics.each { |k, _| assert_equal 3, analytics[k].length }

    get "/analytics?year=2014&month=04"
    assert last_response.ok?
    analytics = MultiJson.load(last_response.body)

    assert_equal 6, analytics.length
    assert_equal 20376, analytics["SNOMEDCT"]["2014"]["4"]
    assert_equal 1, analytics["SNOMEDCT"].length
    assert_equal 12, analytics["CMPO"]["2014"]["4"]
    analytics.values.each { |v| assert_equal 1, v.length; assert_equal "2014", v.keys[0]; assert_equal "4", v[v.keys[0]].keys[0] }

    get "/analytics"
    assert last_response.ok?
    analytics = MultiJson.load(last_response.body)
    assert_equal 6, analytics.length
    analytics.each { |k, _| assert_equal 3, analytics[k].length }

    get "/ontologies/NON_EXISTENT/analytics"
    assert_equal(404, last_response.status, msg=get_errors(last_response))

    get "/ontologies/TST/analytics"
    assert last_response.ok?
    analytics = MultiJson.load(last_response.body)
    assert_equal 1, analytics.length
    assert_equal 3, analytics[analytics.keys[0]].length
    assert_equal 2000, analytics["TST"]["2015"]["1"]

    get '/ontologies/TST/analytics?format=csv'
    assert last_response.ok?
    headers = last_response.headers
    assert_equal "text/csv;charset=utf-8", headers["Content-Type"]
    assert_equal 'attachment; filename="analytics-TST.csv"', headers["Content-Disposition"]
  end

end
