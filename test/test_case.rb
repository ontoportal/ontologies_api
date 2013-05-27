# Start simplecov if this is a coverage task
if ENV["COVERAGE"].eql?("true")
  require 'simplecov'
  SimpleCov.start do
    add_filter "/test/"
    add_filter "app.rb"
    add_filter "init.rb"
    add_filter "/config/"
  end
end

require_relative '../app'
require 'minitest/unit'
MiniTest::Unit.autorun
require 'rack/test'
require 'multi_json'
require 'oj'
require 'json-schema'

ENV['RACK_ENV'] = 'test'

# Check to make sure you want to run if not pointed at localhost
safe_host = Regexp.new(/localhost|ncbo-dev*/)
unless LinkedData.settings.goo_host.match(safe_host) && LinkedData.settings.search_server_url.match(safe_host) && LinkedData.settings.redis_host.match(safe_host)
  print "\n\n================================== WARNING ==================================\n"
  print "** TESTS CAN BE DESTRUCTIVE -- YOU ARE POINTING TO A POTENTIAL PRODUCTION/STAGE SERVER **\n"
  print "Servers:\n"
  print "triplestore -- #{LinkedData.settings.goo_host}\n"
  print "search -- #{LinkedData.settings.search_server_url}\n"
  print "redis -- #{LinkedData.settings.redis_host}\n"
  print "Type 'y' to continue: "
  $stdout.flush
  confirm = $stdin.gets
  if !(confirm.strip == 'y')
    abort("Canceling tests...\n\n")
  end
  print "Running tests..."
  $stdout.flush
end

class AppUnit < MiniTest::Unit
  def before_suites
    # code to run before the first test (gets inherited in sub-tests)
  end

  def after_suites
    # code to run after the last test (gets inherited in sub-tests)
  end

  def _run_suites(suites, type)
    begin
      before_suites
      super(suites, type)
    ensure
      after_suites
    end
  end

  def _run_suite(suite, type)
    begin
      suite.before_suite if suite.respond_to?(:before_suite)
      super(suite, type)
    ensure
      suite.after_suite if suite.respond_to?(:after_suite)
    end
  end
end

AppUnit.runner = AppUnit.new

# All tests should inherit from this class.
# Use 'rake test' from the command line to run tests.
# See http://www.sinatrarb.com/testing.html for testing information
class TestCase < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def teardown
  end

  ##
  # Creates a set of Ontology and OntologySubmission objects and stores them in the triplestore
  # @param [Hash] options the options to create ontologies with
  # @option options [Fixnum] :ont_count Number of ontologies to create
  # @option options [Fixnum] :submission_count How many submissions each ontology should have (acts as max number when random submission count is used)
  # @option options [TrueClass, FalseClass] :random_submission_count Use a random number of submissions between 1 and :submission_count
  # @option options [TrueClass, FalseClass] :process_submission Parse the test ontology file
  def create_ontologies_and_submissions(options = {})
    LinkedData::SampleData::Ontology.create_ontologies_and_submissions(options)
  end

  ##
  # Delete all ontologies and their submissions
  def delete_ontologies_and_submissions
    LinkedData::SampleData::Ontology.delete_ontologies_and_submissions
  end

  # Delete triple store models
  # @param [Array] gooModelArray an array of GOO models
  def delete_goo_models(gooModelArray)
    gooModelArray.each do |m|
      next if m.nil?
      m.load
      m.delete
    end
  end

  # Validate JSON object against a JSON schema.
  # @note schema is only validated after json data fails to validate.
  # @param [String] jsonData a json string that will be parsed by MultiJson.load
  # @param [String] jsonSchemaString a json schema string that will be parsed by MultiJson.load
  # @param [boolean] list set it true for jsonObj array of items to validate against jsonSchemaString
  def validate_json(jsonData, jsonSchemaString, list=false)
    jsonObj = MultiJson.load(jsonData)
    jsonSchema = MultiJson.load(jsonSchemaString)
    assert(
        JSON::Validator.validate(jsonSchema, jsonObj, :list => list),
        JSON::Validator.fully_validate(jsonSchema, jsonObj, :validate_schema => true, :list => list).to_s
    )
  end

end
