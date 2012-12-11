require "ontologies_linked_data"

# The classes defined here are simple wrappers around objects that exist in other namespaces
# Wrapping them here allows access to them without using the full namespace.
# If additional functionality is needed for ontologies_api only, the class should be moved to its own model file.

Category = LinkedData::Models::Category

Group = LinkedData::Models::Group

Ontology = LinkedData::Models::Ontology

Project = LinkedData::Models::Project

Review = LinkedData::Models::Review

User = LinkedData::Models::User
