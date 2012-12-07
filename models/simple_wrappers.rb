# The classes defined here are simple wrappers around objects that exist in other namespaces
# Wrapping them here allows access to them without using the full namespace.
# If additional functionality is needed for ontologies_api only, the class should be moved to its own model file.

class Category < LinkedData::Models::Category; end

class Group < LinkedData::Models::Group; end

class Ontology < LinkedData::Models::Ontology; end

class Project < LinkedData::Models::Project; end

class Review < LinkedData::Models::Review; end

class User < LinkedData::Models::User; end