
require 'ncbo_resource_index'

#  @options[:resource_index_location]  = "http://rest.bioontology.org/resource_index/"
#  @options[:filterNumber]             = true
#  @options[:isStopWordsCaseSensitive] = false
#  @options[:isVirtualOntologyId]      = true
#  @options[:levelMax]                 = 0
#  @options[:longestOnly]              = false
#  @options[:ontologiesToExpand]       = []
#  @options[:ontologiesToKeepInResult] = []
#  @options[:mappingTypes]             = []
#  @options[:minTermSize]              = 3
#  @options[:scored]                   = true
#  @options[:semanticTypes]            = []
#  @options[:stopWords]                = []
#  @options[:wholeWordOnly]            = true
#  @options[:withDefaultStopWords]     = true
#  @options[:withSynonyms]             = true
#  @options[:conceptids]               = []
#  @options[:mode]                     = :union
#  @options[:elementid]                = []
#  @options[:resourceids]              = []
#  @options[:elementDetails]           = false
#  @options[:withContext]              = true
#  @options[:offset]                   = 0
#  @options[:limit]                    = 10
#  @options[:format]                   = :xml
#  @options[:counts]                   = false
#  @options[:request_timeout]          = 300


class ResourceIndexController < ApplicationController

  @@ncboJenkinsApiKey="ccd30807-516a-4b1a-809d-5a88d34c57f4"
  @ri = NCBO::ResourceIndex.new(:apikey => @@ncboJenkinsApiKey)

  namespace "/resource_index/search" do
    # Return search results
    get do
      #reply MODEL.all(load_attrs: MODEL.goo_attrs_to_load)
    end

    #
    # No other HTTP methods are supported for search.
    #
  end

  namespace "/resource_index/resources" do

    # Return resource index resources
    get do
      #reply MODEL.all(load_attrs: MODEL.goo_attrs_to_load)
    end

    get "/:resource_id" do
      #reply MODEL.all(load_attrs: MODEL.goo_attrs_to_load)
    end

    get "/:resource_id/elements/:element_id" do
      #reply MODEL.all(load_attrs: MODEL.goo_attrs_to_load)
      #result_concept = ri.find_by_concept(["1032/Melanoma"])
      #result_element = ri.find_by_element("E-GEOD-19229", "GEO")
    end

    #
    # No other HTTP methods are supported for resources?
    #
  end

end

