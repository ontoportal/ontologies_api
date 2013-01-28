require_relative '../test_case'

class TestgroupsController < TestCase

  def setup
    # Create some test groups
    @groups = {
      "CTSA-HOM" => ["CTSA Health Ontology Mapper Cancer", "CTSA Health Ontology Mapper Cancer Description"],
      "caBIG" => ["Biomedical Informatics Grid", "Biomedical Info Grid Description"],
      "CTSA" => ["Clinical and Translational Science Awards", "CTSA Description"],
      "CGIAR" => ["Consultative Group on International Agricultural Research", "Consultative Group Description"],
      "OBOF" => ["OBO Foundry", "OBO Foundry Description"],
      "PSI" => ["Proteomics Standards Initiative", "Proteomics Group Description"],
      "UMLS" => ["Unified Medical Language System",  "UMLS Group Description"],
      "WHO-FIC" => ["WHO Family of International Classifications", "WHO Description"]
    }

    # Make sure these don't exist
    _delete_groups

    i = 0
    # Create them again
    @groups.each do |acronym, name_desc|
      Group.new(acronym: acronym, name: name_desc[0], description: name_desc[1]).save
      i += 1
    end
 end

  def teardown
    # Delete groups
    _delete_groups
  end

  def _delete_groups
    @groups.each do |acronym, name_desc|
      group = Group.find(acronym)
      group.delete unless group.nil?
    end
  end


  def test_all_groups
    get '/groups'
    assert last_response.ok?
    groups = JSON.parse(last_response.body)
    assert groups.length >= @groups.length
  end

  def test_single_group
    group = 'test_group'
    get "/groups/#{group}"
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_create_new_group
  end

  def test_update_replace_group
  end

  def test_update_patch_group
  end

  def test_delete_group
  end

end