require 'csv'
require 'cgi'
require 'google/api_client'
require 'google/api_client/auth/installed_app'


class CCVController < ApplicationController

  ##
  # get all ontology analytics for a given year/month combination
  namespace "/ccv" do

    get do
      reply 200, process_concept_search
    end

    private

    def process_concept_search(params=nil)
      ont_url = lambda { |acronym| "http://bioportal.bioontology.org/ontologies/#{acronym}" }
      concept_url = lambda { |acronym, uri| "#{ont_url.call(acronym)}?p=classes&conceptid=#{CGI.escape(uri)}" }

      params ||= @params
      params["exact_match"] = true
      text = params["q"]

      include_family = params["include_family"].eql?('true') # default = false
      include_analytics = params["include_analytics"].eql?('true') # default = false
      include_images = params["include_images"].eql?('true') # default = false

      query = get_edismax_query(text, params)
      set_page_params(params)

      loaded_submissions = Hash.new
      loaded_ontologies = Array.new
      resp = LinkedData::Models::Class.search(query, params)
      total_found = resp["response"]["numFound"]
      agg_doc = {"term" => text, "ids" => [], "ontologies" => []}

      all_synonyms = Hash.new
      all_definitions = Hash.new
      all_parents = Hash.new
      all_children = Hash.new

      resp["response"]["docs"].each do |doc|
        doc = doc.symbolize_keys
        resource_id = doc[:resource_id]
        acronym = doc[:submissionAcronym]
        ontology_uri = doc[:ontologyId].first.sub(/\/submissions\/.*/, "")
        ontology_rank = LinkedData::OntologiesAPI.settings.ontology_rank[acronym] || 0
        doc[:synonym] ||= []
        doc[:definition] ||= []

        agg_doc["ids"] << {"id" => resource_id, "ui" => concept_url.call(acronym, resource_id)}

        if (!loaded_ontologies.include?(acronym))
          ont_doc = {"id" => ontology_uri, "acronym" => acronym, "rank" => ontology_rank, "ui" => ont_url.call(acronym)}
          agg_doc["ontologies"] << ont_doc
          loaded_ontologies << acronym
        end

        aggregate_vals(all_synonyms, doc[:synonym], "synonym")
        aggregate_vals(all_definitions, doc[:definition], "definition")

        if include_family
          sub = submission(acronym, loaded_submissions)
          cls_family = class_family(resource_id, sub)
          aggregate_vals(all_parents, cls_family[:parents], "term")
          aggregate_vals(all_children, cls_family[:children], "term")
        end
      end

      agg_doc["synonyms"] = all_synonyms.values
      agg_doc["definitions"] = all_definitions.values

      if include_family
        agg_doc["parents"] = all_parents.values
        agg_doc["children"] = all_children.values
      end

      agg_doc["analytics"] = analytics(text) if include_analytics
      agg_doc["images"] = wikipedia_images(text) if include_images

      agg_doc
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

    def class_family(cls_id, submission)
      cls_family = {parents: [], children: []}

      unless submission.nil?
        cls = LinkedData::Models::Class.find(RDF::URI.new(cls_id)).in(submission).first

        unless cls.nil?
          cls.bring(parents: [:prefLabel])
          cls.bring(children: [:prefLabel])

          cls.parents.each do |p|
            begin
              cls_family[:parents] << p.prefLabel
            rescue Exception => e
            end
          end

          cls.children.each do |c|
            begin
              cls_family[:children] << c.prefLabel
            rescue Exception => e
            end
          end
        end
      end
      cls_family
    end

    def submission(acronym, loaded_submissions)
      return loaded_submissions[acronym] if loaded_submissions.has_key?(acronym)
      sub = nil
      ont = Ontology.find(acronym).include(submissions: [:submissionId, submissionStatus: [:code], ontology: [:acronym]]).first
      sub = ont.latest_submission(status: :rdf) unless ont.nil?
      loaded_submissions[acronym] = sub
      sub
    end

    def analytics(query)
      max_results = 10000
      start_index = 1
      aggregated_results = Hash.new
      start_date = "2014-01-01"
      start_year = 2014

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

    def wikipedia_images(query)
      ignore_images = ["File:Closed Access logo alternative.svg", "File:Commons-logo.svg", "File:Wiktionary-logo-en.svg", "File:Mergefrom.svg"]
      images_url = "https://en.wikipedia.org/w/api.php?action=query&titles=#{CGI.escape(query)}&prop=images&format=json&imlimit=10"
      single_image_url = lambda { |i| "https://en.wikipedia.org/w/api.php?action=query&titles=#{i}&prop=imageinfo&iiprop=url&format=json" }
      resp_raw = Net::HTTP.get_response(URI.parse(images_url))
      resp = MultiJson.load(resp_raw.body)
      images = []

      if resp["query"]["pages"]
        img_hash = resp["query"]["pages"][resp["query"]["pages"].keys[0]]

        if img_hash["images"] && !img_hash["images"].empty?
          img_hash["images"].each do |i|
            next if ignore_images.include?(i["title"])
            img_title = CGI.escape(i["title"])
            resp_img_raw = Net::HTTP.get_response(URI.parse(single_image_url.call(img_title)))
            resp_img = MultiJson.load(resp_img_raw.body)

            if resp_img["query"]["pages"]
              img_info_hash = resp_img["query"]["pages"][resp_img["query"]["pages"].keys[0]]
              images << img_info_hash["imageinfo"][0]["url"]
            end
          end
        end
      end
      images
    end

  end

end
