require_relative '../test_case'
require "multi_json"

class TestAgentsController < TestCase

  def setup

    @number_of_organizations = 6


    @test_agents = 8.times.map do |i|
      type = i < @number_of_organizations ? 'organization' : 'person'
      _agent_data(type: type)
    end
    @agents = []
    2.times.map do
      agents_tmp = [ _agent_data(type: 'organization'), _agent_data(type: 'organization'), _agent_data(type: 'person')]
      agent = agents_tmp.last
      agent[:affiliations] = [agents_tmp[0].stringify_keys, agents_tmp[1].stringify_keys]
      _test_agent_creation(agent)
      @agents = @agents  + agents_tmp
    end
  end

  def teardown
    # Delete groups
    _delete_agents
  end

  def test_all_agents
    get '/agents?display=all&page=1'
    assert last_response.ok?

    created_agents = MultiJson.load(last_response.body)
    @agents.each do |agent|
      created_agent = created_agents["collection"].select{|x| x["name"].eql?(agent[:name])}.first
      refute_nil created_agent
      refute_nil created_agent["usages"]
      assert_equal agent[:name], created_agent["name"]
      assert_equal agent[:identifiers].size, created_agent["identifiers"].size
      assert_equal agent[:identifiers].map{|x| x[:notation]}.sort, created_agent["identifiers"].map{|x| x['notation']}.sort
      assert_equal agent[:affiliations].size, created_agent["affiliations"].size
      assert_equal agent[:affiliations].map{|x| x["name"]}.sort, created_agent["affiliations"].map{|x| x['name']}.sort

    end
  end

  def test_single_agent
    @agents.each do |agent|
      agent_obj = _find_agent(agent['name'])
      get "/agents/#{agent_obj.id.to_s.split('/').last}"
      assert last_response.ok?
      agent_found = MultiJson.load(last_response.body)
      assert_equal agent_obj.id.to_s, agent_found["id"]
    end
  end

  def test_create_new_agent

    ## Create Agent of type affiliation with no parent affiliation
    agent = @test_agents[0]
    created_agent = _test_agent_creation(agent)

    ## Create Agent of type affiliation with an extent parent affiliation

    agent = @test_agents[1]
    agent[:affiliations] = [created_agent]

    created_agent = _test_agent_creation(agent)

    ## Create Agent of type affiliation with an no extent parent affiliation
    agent = @test_agents[3]
    agent[:affiliations] = [created_agent, @test_agents[2].stringify_keys]
    created_agent = _test_agent_creation(agent)

    ## Create Agent of type Person with an extent affiliations

    agent = @test_agents[6]
    agent[:affiliations] = created_agent["affiliations"]
    _test_agent_creation(agent)

    ## Create Agent of type Person with no extent affiliations

    agent = @test_agents[7]
    agent[:affiliations] = [@test_agents[4].stringify_keys, @test_agents[5].stringify_keys]
    _test_agent_creation(agent)

    @agents = @agents + @test_agents
  end


  def test_new_agent_no_valid
    agents_tmp = [ _agent_data(type: 'organization'), _agent_data(type: 'person'), _agent_data(type: 'person')]
    agent = agents_tmp.last
    agent[:affiliations] = [agents_tmp[0].stringify_keys, agents_tmp[1].stringify_keys]
    post "/agents", MultiJson.dump(agent), "CONTENT_TYPE" => "application/json"
    assert last_response.status == 400
  end

  def test_update_patch_agent

    agents = [ _agent_data(type: 'organization'), _agent_data(type: 'organization'), _agent_data(type: 'person')]
    agent = agents.last
    agent[:affiliations] = [agents[0].stringify_keys, agents[1].stringify_keys]
    agent = _test_agent_creation(agent)
    @agents = @agents + agents
    agent = LinkedData::Models::Agent.find(agent['id'].split('/').last).first
    agent.bring_remaining


    ## update identifiers
    agent.identifiers.each{|i| i.bring_remaining}
    new_identifiers = []
    ## update an existent identifier
    new_identifiers[0] = {
      id: agent.identifiers[0].id.to_s,
      schemaAgency: 'TEST ' + agent.identifiers[0].notation
    }

    new_identifiers[1] = {
      id: agent.identifiers[1].id.to_s
    }

    ## update affiliation
    agent.affiliations.each{|aff| aff.bring_remaining}
    new_affiliations = []
    ## update an existent affiliation
    new_affiliations[0] =  {
      name: 'TEST new of ' +  agent.affiliations[0].name,
      id: agent.affiliations[0].id.to_s
    }
    ## create a new affiliation
    new_affiliations[1] = _agent_data(type: 'organization')
    new_affiliations[1][:name] = 'new affiliation'

    new_values = {
      name: 'new name ',
      identifiers: new_identifiers,
      affiliations: new_affiliations
    }

    patch "/agents/#{agent.id.split('/').last}", MultiJson.dump(new_values), "CONTENT_TYPE" => "application/json"
    assert last_response.status == 204

    get "/agents/#{agent.id.split('/').last}"
    new_agent = MultiJson.load(last_response.body)
    assert_equal 'new name ', new_agent["name"]

    assert_equal new_identifiers.size, new_agent["identifiers"].size
    assert_equal new_identifiers[0][:schemaAgency], new_agent["identifiers"].select{|x| x["id"].eql?(agent.identifiers[0].id.to_s)}.first["schemaAgency"]
    assert_equal agent.identifiers[1].schemaAgency, new_agent["identifiers"].select{|x| x["id"].eql?(agent.identifiers[1].id.to_s)}.first["schemaAgency"]

    assert_equal new_affiliations.size, new_agent["affiliations"].size
    assert_equal new_affiliations[0][:name], new_agent["affiliations"].select{|x| x["id"].eql?(agent.affiliations[0].id.to_s)}.first["name"]
    assert_nil new_agent["affiliations"].select{|x| x["id"].eql?(agent.affiliations[1].id.to_s)}.first
    assert_equal new_affiliations[1][:name], new_agent["affiliations"].reject{|x| x["id"].eql?(agent.affiliations[0].id.to_s)}.first["name"]
  end

  def test_delete_agent
    agent = @agents.delete_at(0)
    agent_obj = _find_agent(agent['name'])
    id = agent_obj.id.to_s.split('/').last
    delete "/agents/#{id}"
    assert last_response.status == 204

    get "/agents/#{id}"
    assert last_response.status == 404
  end

  private

  def _agent_data(type: 'organization')
    agent_data(type: type)
  end

  def _find_agent(name)
    LinkedData::Models::Agent.where(name: name).first
  end

  def _delete_agents
    @agents.each do |agent|
      test_cat = _find_agent(agent[:name])
      next if test_cat.nil?

      test_cat.bring :identifiers
      test_cat.identifiers.each { |i| i.delete }
      test_cat.delete
    end
  end

  def _test_agent_creation(agent)
    post "/agents", MultiJson.dump(agent), "CONTENT_TYPE" => "application/json"

    assert last_response.status == 201
    created_agent = MultiJson.load(last_response.body)
    assert created_agent["name"].eql?(agent[:name])

    get "/agents/#{created_agent['id'].split('/').last}"
    assert last_response.ok?

    created_agent = MultiJson.load(last_response.body)
    assert_equal agent[:name], created_agent["name"]
    assert_equal agent[:identifiers].size, created_agent["identifiers"].size
    assert_equal agent[:identifiers].map { |x| x[:notation] }.sort, created_agent["identifiers"].map { |x| x['notation'] }.sort

    assert_equal agent[:affiliations].size, created_agent["affiliations"].size
    assert_equal agent[:affiliations].map { |x| x["name"] }.sort, created_agent["affiliations"].map { |x| x['name'] }.sort
    created_agent
  end
end