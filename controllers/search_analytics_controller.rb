require 'csv'

require 'google/api_client'
require 'google/api_client/auth/installed_app'


class SearchAnalyticsController < ApplicationController

  ##
  # get all ontology analytics for a given year/month combination
  namespace "/ccv" do

    get do
      json = '{
  "term": "melanoma",
  "ids": [
    {
      "id": "http://ncicb.nci.nih.gov/xml/owl/EVS/Thesaurus.owl#C7058",
      "ui": "http://bioportal.bioontology.org/ontologies/NCIT?p=classes&conceptid=http%3A%2F%2Fncicb.nci.nih.gov%2Fxml%2Fowl%2FEVS%2FThesaurus.owl%23C7058"
    },
    {
      "id": "http://purl.obolibrary.org/obo/DOID_1909",
      "ui": "http://bioportal.bioontology.org/ontologies/DOID?p=classes&conceptid=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FDOID_1909"
    },
    {
      "id": "http://purl.bioontology.org/ontology/MEDDRA/10053571",
      "ui": "http://bioportal.bioontology.org/ontologies/MEDDRA?p=classes&conceptid=http%3A%2F%2Fpurl.bioontology.org%2Fontology%2FMEDDRA%2F10053571"
    },
    {
      "id": "http://purl.obolibrary.org/obo/HP_0002861",
      "ui": "http://bioportal.bioontology.org/ontologies/HP?p=classes&conceptid=http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FHP_0002861"
    }
  ],
  "ontologies": [
    {
      "id": "http://data.bioontology.org/ontologies/NCIT",
      "acronym": "NCIT",
      "ui": "http://bioportal.bioontology.org/ontologies/NCIT"
    },
    {
      "id": "http://data.bioontology.org/ontologies/DOID",
      "acronym": "DOID",
      "ui": "http://bioportal.bioontology.org/ontologies/DOID"
    },
    {
      "id": "http://data.bioontology.org/ontologies/MEDDRA",
      "acronym": "MEDDRA",
      "ui": "http://bioportal.bioontology.org/ontologies/MEDDRA"
    }
  ],
  "definitions": [
    "A malignant, usually aggressive tumor composed of atypical, neoplastic melanocytes. Most often, melanomas arise in the skin (cutaneous melanomas) and include the following histologic subtypes: superficial spreading melanoma, nodular melanoma, acral lentiginous melanoma, and lentigo maligna melanoma. Cutaneous melanomas may arise from acquired or congenital melanocytic or dysplastic nevi. Melanomas may also arise in other anatomic sites including the gastrointestinal system, eye, urinary tract, and reproductive system. Melanomas frequently metastasize to lymph nodes, liver, lungs, and brain.",
    "The presence of a melanoma, a malignant cancer originating from pigment producing melanocytes. Melanoma can originate from the skin or the pigmented layers of the eye (the uvea).",
    "A malignant neoplasm derived from cells that are capable of forming melanin, which may occur in the skin of any part of the body, in the eye, or, rarely, in the mucous membranes of the genitalia, anus, oral cavity, or other sites. It occurs mostly in adults and may originate de novo or from a pigmented nevus or malignant lentigo. Melanomas frequently metastasize widely, and the regional lymph nodes, liver, lungs, and brain are likely to be involved. The incidence of malignant skin melanomas is rising rapidly in all parts of the world. (Stedman, 25th ed; from Rook et al., Textbook of Dermatology, 4th ed, p2445)"
  ],
  "synonyms": [
    {
      "synonym": "malignant melanoma",
      "count": 4
    },
    {
      "synonym": "melanosarcoma",
      "count": 1
    },
    {
      "synonym": "naevocarcinoma",
      "count": 1
    }
  ],
  "parents": [
    {
      "term": "Neoplasm by histology",
      "count": 2
    }
  ],
  "children": [
    {
      "term": "Extracutaneous melanoma",
      "count": 17
    },
    {
      "term": "Cutaneous melanoma",
      "count": 12
    },
    {
      "term": "Breast melanoma",
      "count": 4
    }
  ],
  "siblings": [
    {
      "term": "Sibling 1",
      "count": 11
    },
    {
      "term": "Sibling 2",
      "count": 3
    }
  ],
  "analytics": {
    "2014": {
      "1": 41,
      "2": 2,
      "3": 3,
      "4": 2,
      "5": 9,
      "6": 3,
      "7": 0,
      "8": 15,
      "9": 5,
      "10": 2,
      "11": 8,
      "12": 6
    },
    "2015": {
      "1": 4,
      "2": 6,
      "3": 12,
      "4": 2,
      "5": 9,
      "6": 3,
      "7": 0,
      "8": 15,
      "9": 5,
      "10": 2,
      "11": 8,
      "12" : 0
    }
  }
}'

      reply 200, JSON.parse(json)





      # process_search()

    end


    def search_results(params=nil)
      params ||= @params
      params["exact_match"] = true
      text = params["q"]
      query = get_edismax_query(text, params)

      # binding.pry

      resp = LinkedData::Models::Class.search(query, params)
      reply 200, [resp]
    end


    def process_search(params=nil)
      params ||= @params
      text = params[:concept]

      query = get_edismax_query(text, params)
      # puts "Edismax query: #{query}, params: #{params}"
      set_page_params(params)

      docs = Array.new
      resp = LinkedData::Models::Class.search(query, params)
      total_found = resp["response"]["numFound"]
      add_matched_fields(resp)

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
        ontology_uri = doc[:ontologyId].first.sub(/\/submissions\/.*/, "") rescue next
        ontology = LinkedData::Models::Ontology.read_only(id: ontology_uri, acronym: doc[:submissionAcronym])
        submission = LinkedData::Models::OntologySubmission.read_only(id: doc[:ontologyId], ontology: ontology)
        doc[:submission] = submission
        doc[:ontology_rank] = LinkedData::OntologiesAPI.settings.ontology_rank[doc[:submissionAcronym]] || 0
        doc[:properties] = MultiJson.load(doc.delete(:propertyRaw)) if include_param_contains?(:properties)
        instance = LinkedData::Models::Class.read_only(doc)
        docs.push(instance)
      end

      if (!text.nil? && text[-1] == '*')
        docs.sort! {|a, b| [b[:score], a[:prefLabelExact].downcase, b[:ontology_rank]] <=> [a[:score], b[:prefLabelExact].downcase, a[:ontology_rank]]}
      else
        docs.sort! {|a, b| [b[:score], b[:ontology_rank]] <=> [a[:score], a[:ontology_rank]]}
      end

      #need to return a Page object
      page = page_object(docs, total_found)

      # binding.pry

      analytics(text)

      reply 200, resp["response"]
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
