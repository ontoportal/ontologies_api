require 'sinatra/base'

module Sinatra
  module Helpers
    module MappingsHelper
      def convert_mappings_classes(mappings)
        @submissions = {}
        mappings.each do |mapping|
          # Get a list of class objects for each mapping
          classes = []
          mapping.terms.each do |term_mapping|
            next unless term_mapping.loaded_attributes.include?(:term)
            term_mapping.term.each do |term|
              unless @submissions[term_mapping.ontology]
                ont = term_mapping.ontology
                submission = LinkedData::Models::OntologySubmission.read_only(id: ont.id.to_s + "/submissions/latest", ontology: ont)
                @submissions[term_mapping.ontology] = submission
              end
              cls = LinkedData::Models::Class.read_only(id: term, submission: @submissions[term_mapping.ontology])
              classes << cls
            end
          end

          # The serializer will output the "classes" attribute if we
          # define the attribute and a getter here. This should only
          # run if the mapping class hasn't already had this getter defined
          unless mapping.class.public_methods(false).include?(:classes)
            mapping.class.class_eval do
              define_method :classes do
                instance_variable_get("@classes")
              end
            end
          end
          mapping.instance_variable_set("@classes", classes)
        end
      end
    end
  end
end

helpers Sinatra::Helpers::MappingsHelper
