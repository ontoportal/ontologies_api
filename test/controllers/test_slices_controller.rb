require_relative '../test_case'

class TestSlicesController < TestCase

  def self.before_suite
    onts = LinkedData::SampleData::Ontology.create_ontologies_and_submissions(ont_count: 1, submission_count: 0)[2]

    @@slice_acronyms = ["tst-a", "tst-b"].sort
    _create_slice(@@slice_acronyms[0], "Test Slice A", onts)
    _create_slice(@@slice_acronyms[1], "Test Slice B", onts)
  end

  def test_all_slices
    get "/slices"
    assert last_response.ok?
    slices = MultiJson.load(last_response.body)
    assert_equal @@slice_acronyms, slices.map {|s| s["acronym"]}.sort
  end

  private

  def self._create_slice(acronym, name, ontologies)
    slice = LinkedData::Models::Slice.new({
      acronym: acronym,
      name: "Test #{name}",
      ontologies: ontologies
    })
    slice.save
  end
end
