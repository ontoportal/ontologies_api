require 'csv'
require 'cgi'
require 'google/api_client'
require 'google/api_client/auth/installed_app'


class CCVController < ApplicationController

  ##
  # get all ontology analytics for a given year/month combination
  namespace "/ccv" do

    get do

      process_search()

    end

    def process_search(params=nil)
      ont_url = lambda { |acronym| "http://bioportal.bioontology.org/ontologies/#{acronym}" }
      concept_url = lambda { |acronym, uri| "#{ont_url.call(acronym)}?p=classes&conceptid=#{CGI.escape(uri)}" }


      params ||= @params
      params["exact_match"] = true
      text = params["q"]

      query = get_edismax_query(text, params)
      set_page_params(params)

      docs = Array.new
      loaded_ontologies_submissions = Hash.new
      loaded_ontologies = Array.new
      resp = LinkedData::Models::Class.search(query, params)
      total_found = resp["response"]["numFound"]


      agg_doc = {"term" => text, "ids" => [], "ontologies" => [], "definitions" => [], "synonyms" => [], "parents" => [], "children" => [], "analytics" => Hash.new}


      all_synonyms = Hash.new
      all_definitions = Hash.new
      all_parents = Hash.new
      all_children = Hash.new

      resp["response"]["docs"].each do |doc|
        doc = doc.symbolize_keys
        resource_id = doc[:resource_id]
        # doc.delete :resource_id
        # doc[:id] = resource_id
        ontology_uri = doc[:ontologyId].first.sub(/\/submissions\/.*/, "")

        # doc.delete :prefLabelExact
        # doc.delete :prefLabelSuggest
        # doc.delete :prefLabelSuggestEdge
        # doc.delete :prefLabelSuggestNgram
        # doc.delete :synonymExact
        # doc.delete :synonymSuggest
        # doc.delete :synonymSuggestEdge
        # doc.delete :synonymSuggestNgram
        # doc.delete :childCount
        # doc.delete :notation
        # doc.delete :property
        # doc.delete :propertyRaw
        # doc.delete :_version_
        # doc.delete :ontologyType
        # doc.delete :obsolete
        # doc.delete :provisional
        # doc.delete :ontologyId

        ontology_rank = LinkedData::OntologiesAPI.settings.ontology_rank[doc[:submissionAcronym]] || 0
        # doc[:ontology] = {"id" => ontology_uri, "acronym" => doc[:submissionAcronym], "rank" => ontology_rank}
        doc[:synonym] ||= []
        doc[:definition] ||= []

        ont, sub = ontology_and_submission(doc[:submissionAcronym], loaded_ontologies_submissions)
        cls_info = get_class_info(resource_id, sub)
        c_info = cls_info

        # doc[:properties] = MultiJson.load(doc.delete(:propertyRaw)) if include_param_contains?(:properties)


        # docs.push(doc)




        agg_doc["ids"] << {"id" => resource_id, "ui" => concept_url.call(doc[:submissionAcronym], resource_id)}

        if (!loaded_ontologies.include?(doc[:submissionAcronym]))
          ont_doc = {"id" => ontology_uri, "acronym" => doc[:submissionAcronym], "rank" => ontology_rank, "ui" => ont_url.call(doc[:submissionAcronym])}
          agg_doc["ontologies"] << ont_doc
          loaded_ontologies << doc[:submissionAcronym]
        end

        aggregate_vals(all_synonyms, doc[:synonym], "synonym")
        aggregate_vals(all_definitions, doc[:definition], "definition")
        aggregate_vals(all_parents, c_info[:parents], "term")
        aggregate_vals(all_children, c_info[:children], "term")
      end

      agg_doc["synonyms"] = all_synonyms.values
      agg_doc["definitions"] = all_definitions.values
      agg_doc["parents"] = all_parents.values
      agg_doc["children"] = all_children.values

      agg_doc["analytics"] = analytics(text)

      reply 200, agg_doc
    end




    def aggregate_vals(master_hash, data, label)
      data.each do |k|
        if master_hash.has_key?(k)
          master_hash[k]["count"] += 1
        else
          master_hash[k] = Hash.new
          master_hash[k][label] = k
          master_hash[k]["count"] = 1
        end
      end
    end

    def get_class_info(cls_id, submission)
      cls_info = {parents: [], children: []}

      unless submission.nil?
        cls = LinkedData::Models::Class.find(RDF::URI.new(cls_id)).in(submission).first

        unless cls.nil?
          cls.bring(parents: [:prefLabel])
          cls.bring(children: [:prefLabel])

          cls.parents.each do |p|
            begin
              cls_info[:parents] << p.prefLabel
            rescue Exception => e
            end
          end

          cls.children.each do |c|
            begin
              cls_info[:children] << c.prefLabel
            rescue Exception => e
            end
          end
        end
      end
      cls_info
    end


    def ontology_and_submission(acronym, loaded_ontologies_submissions)
      return loaded_ontologies_submissions[acronym] if loaded_ontologies_submissions.has_key?(acronym)
      sub = nil
      ont = Ontology.find(acronym).include(submissions: [:submissionId, submissionStatus: [:code], ontology: [:acronym]]).first
      sub = ont.latest_submission(status: [:RDF]) unless ont.nil?
      ont_sub_arr = [ont, sub]
      loaded_ontologies_submissions[acronym] = ont_sub_arr
      ont_sub_arr
    end

    def analytics(query)
      max_results = 10000
      start_index = 1
      aggregated_results = Hash.new
      start_date = "2014-01-01"
      start_year = 2015

      google_client = authenticate_google
      api_method = google_client.discovered_api('analytics', 'v3').data.ga.get

      results = google_client.execute(:api_method => api_method, :parameters => {
          'ids'         => NcboCron.settings.analytics_profile_id,
          'start-date'  => start_date,
          'end-date'    => Date.today.to_s,
          'dimensions'  => 'ga:pagePath,ga:year,ga:month',
          'metrics'     => 'ga:pageviews',
          'filters'     => "ga:pagePath=~^\\/search\\/?\\?q=#{query}.*$",
          'start-index' => start_index,
          'max-results' => max_results
      })

      start_index += max_results
      num_results = results.data.rows.length

      results.data.rows.each do |row|
        if (aggregated_results.has_key?(row[1].to_i))
          # month
          if (aggregated_results[row[1].to_i].has_key?(row[2].to_i))
            aggregated_results[row[1].to_i][row[2].to_i] += row[3].to_i
          else
            aggregated_results[row[1].to_i][row[2].to_i] = row[3].to_i
          end
        else
          aggregated_results[row[1].to_i] = Hash.new
          aggregated_results[row[1].to_i][row[2].to_i] = row[3].to_i
        end
      end

      if (num_results < max_results)
        # fill up non existent years
        (start_year..Date.today.year).each do |y|
          aggregated_results[y] = Hash.new unless aggregated_results.has_key?(y)
        end
        # fill up non existent months with zeros
        (1..12).each { |n| aggregated_results.values.each { |v| v[n] = 0 unless v.has_key?(n) } }
      end

      aggregated_results
    end

    def authenticate_google
      client = Google::APIClient.new(
          :application_name => NcboCron.settings.analytics_app_name,
          :application_version => NcboCron.settings.analytics_app_version
      )
      key = Google::APIClient::KeyUtils.load_from_pkcs12(NcboCron.settings.analytics_path_to_key_file, 'notasecret')
      client.authorization = Signet::OAuth2::Client.new(
          :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
          :audience => 'https://accounts.google.com/o/oauth2/token',
          :scope => 'https://www.googleapis.com/auth/analytics.readonly',
          :issuer => NcboCron.settings.analytics_service_account_email_address,
          :signing_key => key
      )
      client.authorization.fetch_access_token!
      client
    end
  end

end
