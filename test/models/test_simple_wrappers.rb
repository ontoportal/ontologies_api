require "ontologies_linked_data"
require_relative "../test_case"

class TestSimpleWrappers < TestCase
  def test_typing
    assert Category.ancestors.include?(LinkedData::Models::Category)
    assert Group.ancestors.include?(LinkedData::Models::Group)
    assert Ontology.ancestors.include?(LinkedData::Models::Ontology)
    assert Project.ancestors.include?(LinkedData::Models::Project)
    assert Review.ancestors.include?(LinkedData::Models::Review)
    assert User.ancestors.include?(LinkedData::Models::User)
  end
end