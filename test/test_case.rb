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
require 'test/unit'
require 'rack/test'

ENV['RACK_ENV'] = 'test'

# All tests should inherit from this class.
# Use 'rake test' from the command line to run tests.
# See http://www.sinatrarb.com/testing.html for testing information
class TestCase < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def create_ontologies_and_submissions(options = {})
    ont_count = options[:ont_count] || 5
    submission_count = options[:submission_count] || 5
    random_submission_count = options[:random_submission_count].nil? ? true : options[:random_submission_count]

    u = LinkedData::Models::User.new(username: "tim")
    u.save unless u.exist? || !u.valid?

    of = LinkedData::Models::OntologyFormat.new(acronym: "OWL")
    of.save unless u.exist? || !u.valid?

    ont_acronyms = []
    ont_count.to_i.times do |count|
      acronym = "TST-ONT-#{count}"
      ont_acronyms << acronym

      o = LinkedData::Models::Ontology.new({
        acronym: acronym,
        name: "Test Ontology ##{count}",
        administeredBy: u
      })
      o.save if o.valid?

      # Random submissions (between 1 and max)
      max = random_submission_count ? (1..submission_count.to_i).to_a.shuffle.first : submission_count
      max.times do
        os = LinkedData::Models::OntologySubmission.new({
          acronym: "TST-ONT-#{count}",
          ontology: o,
          hasOntologyLanguage: of,
          pullLocation: RDF::IRI.new("http://example.com"),
          submissionStatus: LinkedData::Models::SubmissionStatus.new(:code => "UPLOADED"),
          submissionId: o.next_submission_id
        })
        os.save if os.valid?
      end
    end
    return ont_count, ont_acronyms
  end

  def delete_ontologies_and_submissions
    ont = LinkedData::Models::Ontology.find("TST-ONT-0")
    count = 0
    while ont
      ont.delete
      ont = LinkedData::Models::Ontology.find("TST-ONT-#{count+1}")
    end

    u = LinkedData::Models::User.find("tim")
    u.delete unless u.nil?

    of = LinkedData::Models::OntologyFormat.find("OWL")
    of.delete unless u.nil?
  end

end

