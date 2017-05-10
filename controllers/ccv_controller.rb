class CCVController < ApplicationController

  ##
  # Concept Centric View Controller (BD2K Hackathon, November 19-20, 2015)
  # Michael Dorf, 11/20/15
  #
  namespace "/ccv" do

    ONTOLOGY_URL = lambda { |acronym| "http://bioportal.bioontology.org/ontologies/#{acronym}" }
    CONCEPT_URL = lambda { |acronym, uri| "#{ONTOLOGY_URL.call(acronym)}?p=classes&conceptid=#{CGI.escape(uri)}" }
    WIKIPEDIA_REST_BASE_URL = "https://en.wikipedia.org/w/api.php?action=query"
    WIKIPEDIA_IMAGE_LIMIT = 10
    GOOGLE_IMAGES_REST_BASE_URL = "https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q="
    GOOGLE_IMAGES_IMAGE_LIMIT = 8
    CONCEPT_CHARACTER_LIMIT = 30
    SYNONYMS_FOR_ANALYTICS_LIMIT = 4

    get do
      #TODO: delete when ccv will be on production
      reply(404, "Resource Index is not activated")
      #reply 200, process_concept_search
    end

    # private

    def process_concept_search(params=nil)
      params ||= @params
      params["exact_match"] = true
      text = params["q"]

      include_family = params["include_family"].eql?('true') # default = false
      include_analytics = params["include_analytics"].eql?('true') # default = false
      include_images = params["include_images"].eql?('true') # default = false

      query = get_term_search_query(text, params)
      set_page_params(params)

      loaded_submissions = Hash.new
      loaded_ontologies = Array.new
      resp = LinkedData::Models::Class.search(query, params)
      total_found = resp["response"]["numFound"]
      agg_doc = {"term" => text, "ids" => [], "ontologies" => []}
      all_concepts = Hash.new
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

        # aggregate concept ids
        aggregate_vals(text, all_concepts, resource_id, "id", case_sensitive: true, additional_data: {"ui" => CONCEPT_URL.call(acronym, resource_id)})

        # aggregate ontologies
        if (!loaded_ontologies.include?(acronym))
          ont_doc = {"id" => ontology_uri, "acronym" => acronym, "rank" => ontology_rank, "ui" => ONTOLOGY_URL.call(acronym)}
          agg_doc["ontologies"] << ont_doc
          loaded_ontologies << acronym
        end

        # aggregate synonyms
        aggregate_vals(text, all_synonyms, doc[:synonym], "synonym", char_limit: CONCEPT_CHARACTER_LIMIT)
        # aggregate definitions
        aggregate_vals(text, all_definitions, doc[:definition], "definition", case_sensitive: true)

        if include_family
          sub = submission(acronym, loaded_submissions)
          cls_family = class_family(resource_id, sub)
          # aggregate parents
          aggregate_vals(text, all_parents, cls_family[:parents], "term", char_limit: CONCEPT_CHARACTER_LIMIT)
          # aggregate children
          aggregate_vals(text, all_children, cls_family[:children], "term", char_limit: CONCEPT_CHARACTER_LIMIT)
        end
      end

      agg_doc["ids"] = all_concepts.values
      syn_vals = all_synonyms.values
      agg_doc["synonyms"] = syn_vals
      agg_doc["definitions"] = all_definitions.values

      if include_family
        agg_doc["parents"] = all_parents.values
        agg_doc["children"] = all_children.values
      end

      # give analytics first most relevant synonyms (with most counts), based on SYNONYMS_FOR_ANALYTICS_LIMIT value
      syn_for_analytics = syn_vals.sort_by {|val| val["count"]}.reverse.first(SYNONYMS_FOR_ANALYTICS_LIMIT).map{|val| val["synonym"]}
      agg_doc["analytics"] = analytics(text, syn_for_analytics) if include_analytics
      # removing calls to google images for now, as their API is deprecated
      # if we decided to continue using google images, we must use their latest API intergration
      # agg_doc["images"] = wikipedia_images(text) + google_images(text) if include_images
      agg_doc["images"] = wikipedia_images(text) if include_images
      agg_doc
    end

    def aggregate_vals(query, master_hash, data, label, args={})
      data = [data] unless data.kind_of?(Array)

      data.each do |k|
        k.downcase! unless args[:case_sensitive]
        next if k.casecmp(query) == 0
        next if /([\[\]\(\)]|,\snos|,\sNOS)/.match(k)
        next if args[:char_limit] && k.length > args[:char_limit]

        if master_hash.has_key?(k)
          master_hash[k]["count"] += 1
        else
          master_hash[k] = Hash.new
          master_hash[k][label] = k
          master_hash[k]["count"] = 1

          if args.has_key?(:additional_data)
            args[:additional_data].each do |k1, v|
              master_hash[k][k1] = v
            end
          end
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

    # analytics are calculated based on the term itself as well as its synonyms
    def analytics(query, synonyms)
      aggregated_results = Hash.new
      start_date = "2014-01-01"
      start_year = 2014

      google_client = authenticate_google
      api_method = google_client.discovered_api('analytics', 'v3').data.ga.get
      # use synonyms for analytics results
      synonyms = synonyms.map {|s| escape_characters_in_string(s)}
      # add the query itself to the list to be queried for analytics
      synonyms.unshift(query)

      synonyms.each do |syn|
        max_results = 10000
        num_results = 10000
        start_index = 1

        loop do
          results = google_client.execute(:api_method => api_method, :parameters => {
              'ids'         => NcboCron.settings.analytics_profile_id,
              'start-date'  => start_date,
              'end-date'    => Date.today.to_s,
              'dimensions'  => 'ga:pagePath,ga:year,ga:month',
              'metrics'     => 'ga:pageviews',
              'filters'     => "ga:pagePath=~^\\/search\\/?\\?q=#{syn}.*$",
              'start-index' => start_index,
              'max-results' => max_results
          })

          num_results = results.data.rows.length
          break if num_results == 0
          start_index += max_results

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
            break
          end
        end
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
      images_url = "#{WIKIPEDIA_REST_BASE_URL}&titles=#{CGI.escape(query)}&prop=images&format=json&imlimit=#{WIKIPEDIA_IMAGE_LIMIT}"
      single_image_url = lambda { |i| "#{WIKIPEDIA_REST_BASE_URL}&titles=#{i}&prop=imageinfo&iiprop=url&format=json" }
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
              images << {url: img_info_hash["imageinfo"][0]["url"], source: "wikipedia"}
            end
          end
        end
      end
      images
    end

    def google_images(query)
      images_url = "#{GOOGLE_IMAGES_REST_BASE_URL}#{CGI.escape(query)}&rsz=#{GOOGLE_IMAGES_IMAGE_LIMIT}"
      resp_raw = Net::HTTP.get_response(URI.parse(images_url))
      resp = MultiJson.load(resp_raw.body)
      images = []

      if resp["responseData"]["results"] && !resp["responseData"]["results"].empty?
        img_hash = resp["responseData"]["results"]

        img_hash.each do |i|
          images << {url: i["unescapedUrl"], source: "google"}
        end
      end
      images
    end

    def escape_characters_in_string(string)
      pattern = /(\,|\'|\"|\.|\*|\/|\-|\\)/
      string.gsub(pattern){|match|"\\"  + match}
    end

  end

end
