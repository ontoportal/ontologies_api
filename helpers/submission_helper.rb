require 'sinatra/base'

module Sinatra
  module Helpers
    module SubmissionHelper
      def submission_include_params
        # When asking to display all metadata, we are using bring_remaining on each submission. Slower but best way to retrieve all attrs
        includes = OntologySubmission.goo_attrs_to_load(includes_param)
        if includes.find { |v| v.is_a?(Hash) && v.keys.include?(:ontology) }
          includes << { :ontology => [:administeredBy, :acronym, :name, :viewingRestriction, :group, :hasDomain, :notes, :reviews, :projects, :acl, :viewOf] }
        end

        if includes.find { |v| v.is_a?(Hash) && v.keys.include?(:contact) }
          includes << { :contact => [:name, :email] }
        end

        if includes.find { |v| v.is_a?(Hash) && v.keys.include?(:metrics) }
          includes << { metrics: [:maxChildCount, :properties, :classesWithMoreThan25Children,
                                  :classesWithOneChild, :individuals, :maxDepth, :classes,
                                  :classesWithNoDefinition, :averageChildCount, :numberOfAxioms,
                                  :entities] }
        end

        includes
      end

      def retrieve_submissions(options)
        status = (options[:status] || "RDF").to_s.upcase
        status = "RDF" if status.eql?("READY")
        ontology_acronym = options[:ontology]
        any = status.eql?("ANY")
        include_views = options[:also_include_views] || false
        includes, page, size, order_by, _ = settings_params(LinkedData::Models::OntologySubmission)
        includes << :submissionStatus unless includes.include?(:submissionStatus)

        submissions_query = LinkedData::Models::OntologySubmission
        submissions_query = submissions_query.where(ontology: [acronym: ontology_acronym]) if ontology_acronym

        if any
          submissions_query = submissions_query.where unless ontology_acronym
        else
          submissions_query = submissions_query.where({ submissionStatus: [code: status] })
        end

        submissions_query = submissions_query.order_by(order_by) unless order_by.nil?

        submissions_query = submissions_query.filter(Goo::Filter.new(ontology: [:viewOf]).unbound) unless include_views

        submissions = submissions_query.include(submission_include_params)
        if page?
          submissions.page(page, size).all
        else
          submissions.to_a
        end
      end

      def retrieve_latest_submissions(options = {})
        submissions = retrieve_submissions(options)

        latest_submissions = page? ? submissions : {} # latest_submission doest not work with pagination
        submissions.each do |sub|
          unless page?
            next if include_ready?(options) && !sub.ready?
            next if sub.ontology.nil?
            latest_submissions[sub.ontology.acronym] ||= sub
            latest_submissions[sub.ontology.acronym] = sub if sub.submissionId.to_i > latest_submissions[sub.ontology.acronym].submissionId.to_i
          end
        end
        latest_submissions
      end

      def include_ready?(options)
        options[:status] && options[:status].to_s.upcase.eql?("READY")
      end

    end
  end
end

helpers Sinatra::Helpers::SubmissionHelper