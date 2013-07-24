require_relative '../test_case'

class TestGroupsController < TestCase

  def setup
    # Create some test groups
    @test_group = {acronym: "TEST-GROUP", name: "Test Group", description: "Description of the Test Group"}

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
      group = Group.new(acronym: acronym, name: name_desc[0], description: name_desc[1])
      group.save if group.valid?
      i += 1
    end
  end

  def teardown
    # Delete groups
    _delete_groups
  end

  def _delete_groups
    test_group = Group.find(@test_group[:acronym]).first
    test_group.delete unless test_group.nil?
    @groups.each do |acronym, name_desc|
      group = Group.find(acronym).first
      group.delete unless group.nil?
      assert Group.find(acronym).first.nil?
    end
  end

  def test_all_groups
    get '/groups'
    assert last_response.ok?
    groups = MultiJson.load(last_response.body)
    assert groups.length >= @groups.length
  end

  def test_single_group
    acronym = 'CTSA'
    get "/groups/#{acronym}"
    assert last_response.ok?
    group = MultiJson.load(last_response.body)
    assert group["acronym"] = acronym
  end

  def test_create_new_group
    acronym = @test_group[:acronym]
    put "/groups/#{acronym}", MultiJson.dump(@test_group), "CONTENT_TYPE" => "application/json"

    assert last_response.status == 201
    assert MultiJson.load(last_response.body)["acronym"].eql?(acronym)

    get "/groups/#{acronym}"
    assert last_response.ok?
    assert MultiJson.load(last_response.body)["acronym"].eql?(acronym)

    delete "/groups/#{acronym}"
    post "/groups", MultiJson.dump(@test_group), "CONTENT_TYPE" => "application/json"

    assert last_response.status == 201
    assert MultiJson.load(last_response.body)["acronym"].eql?(acronym)

    get "/groups/#{acronym}"
    assert last_response.ok?
    assert MultiJson.load(last_response.body)["acronym"].eql?(acronym)

  end

  def test_update_patch_group
    acronym = 'CTSA-HOM'
    group = Group.find(acronym).first
    assert_instance_of Group, group
    new_name = "CTSA Health Brand new NAME"
    new_desc = "CTSA Health Brand new DESCRIPTION"
    new_values = {name: new_name, description: new_desc}

    patch "/groups/#{acronym}", MultiJson.dump(new_values), "CONTENT_TYPE" => "application/json"
    assert last_response.status == 204

    get "/groups/#{acronym}"
    group = MultiJson.load(last_response.body)
    assert group["name"].eql?(new_name)
    assert group["description"].eql?(new_desc)
  end

  def test_delete_group
    acronym = 'CTSA-HOM'
    delete "/groups/#{acronym}"
    assert last_response.status == 204

    get "/groups/#{acronym}"
    assert last_response.status == 404
  end
end