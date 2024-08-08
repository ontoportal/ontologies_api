require 'multi_json'
require 'cgi'

class SearchController < ApplicationController
  namespace "/search" do
    # execute a search query
    get do
      process_search
    end

    post do
      process_search
    end

    namespace "/ontologies" do
      get do
        query = params[:query] || params[:q]
        groups = params.fetch("groups", "").split(',')
        categories = params.fetch("hasDomain", "").split(',')
        languages = params.fetch("languages", "").split(',')
        status = params.fetch("status", "").split(',')
        format = params.fetch("hasOntologyLanguage", "").split(',')
        is_of_type = params.fetch("isOfType", "").split(',')
        has_format = params.fetch("hasFormat", "").split(',')
        visibility = params["visibility"]
        show_views = params["show_views"] == 'true'
        sort = params.fetch("sort", "score desc, ontology_name_sort asc, ontology_acronym_sort asc")
        page, page_size = page_params

        fq = [
          'resource_model:"ontology_submission"',
          'submissionStatus_txt:ERROR_* OR submissionStatus_txt:"RDF" OR submissionStatus_txt:"UPLOADED"',
          groups.map { |x| "ontology_group_txt:\"http://data.bioontology.org/groups/#{x.upcase}\"" }.join(' OR '),
          categories.map { |x| "ontology_hasDomain_txt:\"http://data.bioontology.org/categories/#{x.upcase}\"" }.join(' OR '),
          languages.map { |x| "naturalLanguage_txt:\"#{x.downcase}\"" }.join(' OR '),
        ]

        fq << "ontology_viewingRestriction_t:#{visibility}" unless visibility.blank?
        fq << "!ontology_viewOf_t:*" unless show_views

        fq << format.map { |x| "hasOntologyLanguage_t:\"http://data.bioontology.org/ontology_formats/#{x}\"" }.join(' OR ') unless format.blank?

        fq << status.map { |x| "status_t:#{x}" }.join(' OR ') unless status.blank?
        fq << is_of_type.map { |x| "isOfType_t:#{x}" }.join(' OR ') unless is_of_type.blank?
        fq << has_format.map { |x| "hasFormalityLevel_t:#{x}" }.join(' OR ') unless has_format.blank?

        fq.reject!(&:blank?)

        if params[:qf]
          qf = params[:qf]
        else
          qf = [
            "ontology_acronymSuggestEdge^25  ontology_nameSuggestEdge^15 descriptionSuggestEdge^10 ", # start of the word first
            "ontology_acronym_text^15  ontology_name_text^10 description_text^5 ", # full word match
            "ontology_acronymSuggestNgram^2 ontology_nameSuggestNgram^1.5 descriptionSuggestNgram" # substring match last
          ].join(' ')
        end

        page_data = search(Ontology, query, {
          fq: fq,
          qf: qf,
          page: page,
          page_size: page_size,
          sort: sort
        })

        total_found = page_data.aggregate
        ontology_rank = LinkedData::Models::Ontology.rank
        docs = {}
        acronyms_ids = {}
        page_data.each do |doc|
          resource_id = doc["resource_id"]
          id = doc["submissionId_i"]
          acronym = doc["ontology_acronym_text"]
          old_resource_id = acronyms_ids[acronym]
          old_id = old_resource_id.split('/').last.to_i rescue 0

          already_found = (old_id && id && (id <= old_id))
          not_restricted = (doc["ontology_viewingRestriction_t"]&.eql?('public') || current_user&.admin?)
          user_not_restricted = not_restricted ||
            Array(doc["ontology_viewingRestriction_txt"]).any? {|u| u.split(' ').last == current_user&.username} ||
            Array(doc["ontology_acl_txt"]).any? {|u| u.split(' ').last == current_user&.username}

          user_restricted = !user_not_restricted

          if acronym.blank? || already_found || user_restricted
            total_found -= 1
            next
          end

          docs.delete(old_resource_id)
          acronyms_ids[acronym] = resource_id

          doc["ontology_rank"] = ontology_rank.dig(doc["ontology_acronym_text"], :normalizedScore) || 0.0
          docs[resource_id] = doc
        end

        docs = docs.values

        docs.sort! { |a, b| [b["score"], b["ontology_rank"]] <=> [a["score"], a["ontology_rank"]] } unless params[:sort].present?

        page = page_object(docs, total_found)

        reply 200, page
      end

      get '/content' do
        query = params[:query] || params[:q]
        page, page_size = page_params

        ontologies = params.fetch("ontologies", "").split(',')

        unless current_user&.admin?
          restricted_acronyms = restricted_ontologies_to_acronyms(params)
          ontologies = ontologies.empty? ? restricted_acronyms : ontologies & restricted_acronyms
        end


        types = params.fetch("types", "").split(',')
        qf = params.fetch("qf", "")

        qf = [
          "ontology_t^100 resource_id^10",
          "http___www.w3.org_2004_02_skos_core_prefLabel_txt^30",
          "http___www.w3.org_2004_02_skos_core_prefLabel_t^30",
          "http___www.w3.org_2000_01_rdf-schema_label_txt^30",
          "http___www.w3.org_2000_01_rdf-schema_label_t^30",
        ].join(' ') if qf.blank?

        fq = []

        fq << ontologies.map { |x| "ontology_t:\"#{x}\"" }.join(' OR ') unless ontologies.blank?
        fq << types.map { |x| "type_t:\"#{x}\" OR type_txt:\"#{x}\"" }.join(' OR ') unless types.blank?


        conn = SOLR::SolrConnector.new(Goo.search_conf, :ontology_data)
        resp = conn.search(query, fq: fq, qf: qf, defType: "edismax",
                           start: (page - 1) * page_size, rows: page_size)

        total_found = resp["response"]["numFound"]
        docs = resp["response"]["docs"]


        reply 200, page_object(docs, total_found)
      end
    end

    namespace "/agents" do
      get do
        query = params[:query] || params[:q]
        page, page_size = page_params
        type = params[:agentType].blank? ? nil : params[:agentType]

        fq = "agentType_t:#{type}" if type

        if params[:qf]
          qf = params[:qf]
        else
          qf = [
            "acronymSuggestEdge^25  nameSuggestEdge^15 emailSuggestEdge^15 identifiersSuggestEdge^10 ", # start of the word first
            "identifiers_texts^20 acronym_text^15  name_text^10 email_text^10 ", # full word match
            "acronymSuggestNgram^2 nameSuggestNgram^1.5 email_text^1" # substring match last
          ].join(' ')
        end



        if params[:sort]
          sort = "#{params[:sort]} asc, score desc"
        else
          sort = "score desc, acronym_sort asc, name_sort asc"
        end

        reply 200, search(LinkedData::Models::Agent,
                          query,
                          fq: fq, qf: qf,
                          page: page, page_size: page_size,
                          sort: sort)
      end
    end

    private

    def search(model, query, params = {})
      query = query.blank? ? "*" : query

      resp = model.search(query, search_params(params))

      total_found = resp["response"]["numFound"]
      docs = resp["response"]["docs"]

      page_object(docs, total_found)
    end

    def search_params(defType: "edismax", fq:, qf:, stopwords: "true", lowercaseOperators: "true", page:, page_size:, fl: '*,score', sort:)
      {
        defType: defType,
        fq: fq,
        qf: qf,
        sort: sort,
        start: (page - 1) * page_size,
        rows: page_size,
        fl: fl,
        stopwords: stopwords,
        lowercaseOperators: lowercaseOperators,
      }
    end

    def process_search(params = nil)
      params ||= @params
      text = params["q"]

      query = get_term_search_query(text, params)
      # puts "Edismax query: #{query}, params: #{params}"
      set_page_params(params)

      docs = Array.new
      resp = LinkedData::Models::Class.search(query, params)
      total_found = resp["response"]["numFound"]
      add_matched_fields(resp, Sinatra::Helpers::SearchHelper::MATCH_TYPE_PREFLABEL)
      ontology_rank = LinkedData::Models::Ontology.rank

      resp["response"]["docs"].each do |doc|
        doc = doc.symbolize_keys
        # NCBO-974
        doc[:matchType] = resp["match_types"][doc[:id]]
        resource_id = doc[:resource_id]
        doc.delete :resource_id
        doc[:id] = resource_id
        # TODO: The `rescue next` on the following line shouldn't be here
        # However, at some point we didn't store the ontologyId in the index
        # and these records haven't been cleared out so this is getting skipped
        ontology_uri = doc[:ontologyId].sub(/\/submissions\/.*/, "") rescue next
        ontology = LinkedData::Models::Ontology.read_only(id: ontology_uri, acronym: doc[:submissionAcronym])
        submission = LinkedData::Models::OntologySubmission.read_only(id: doc[:ontologyId], ontology: ontology)
        doc[:submission] = submission
        doc[:ontology_rank] = (ontology_rank[doc[:submissionAcronym]] && !ontology_rank[doc[:submissionAcronym]].empty?) ? ontology_rank[doc[:submissionAcronym]][:normalizedScore] : 0.0
        doc[:properties] = MultiJson.load(doc.delete(:propertyRaw)) if include_param_contains?(:properties)

        doc = filter_attrs_by_language(doc)

        instance = doc[:provisional] ? LinkedData::Models::ProvisionalClass.read_only(doc) : LinkedData::Models::Class.read_only(doc)
        docs.push(instance)
      end

      unless params['sort']
        if !text.nil? && text[-1] == '*'
          docs.sort! { |a, b| [b[:score], a[:prefLabelExact].downcase, b[:ontology_rank]] <=> [a[:score], b[:prefLabelExact].downcase, a[:ontology_rank]] }
        else
          docs.sort! { |a, b| [b[:score], b[:ontology_rank]] <=> [a[:score], a[:ontology_rank]] }
        end
      end

      # need to return a Page object
      page = page_object(docs, total_found)

      reply 200, page
    end

  end
end
