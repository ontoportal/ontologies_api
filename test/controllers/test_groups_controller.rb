require_relative '../test_case'

class TestgroupsController < TestCase

  def setup
    # Create some test groups
    @acronyms = %w(CTSA-HOM caBIG CTSA CGIAR OBOF PSI UMLS WHO-FIC)
    @names_descriptions = {
      "CTSA Health Ontology Mapper Cancer" => "CTSA Health Ontology Mapper Cancer Description",
      "Biomedical Informatics Grid" => "Biomedical Info Grid Description",
      "Clinical and Translational Science Awards" => "CTSA Description",
      "Consultative Group on International Agricultural Research" => "Consultative Group Description",
      "OBO Foundry" => "OBO Foundry Description",
      "Proteomics Standards Initiative" => "Proteomics Group Description",
      "Unified Medical Language System" => "UMLS Group Description",
      "WHO Family of International Classifications" => "WHO Description"
    }

    # Make sure these don't exist
    _delete_groups

    i = 0
    # Create them again
    @names_descriptions.each do |name, desc|
      Group.new(acronym: @acronyms[i], name: name, description: desc).save
      i += 1
    end
 end

  def teardown
    # Delete groups
    _delete_groups
  end

  def _delete_groups
    @acronyms.each do |acronym|
      group = Group.find(acronym)
      group.delete unless group.nil?
    end
  end


  def test_all_groups
    get '/groups'
    assert last_response.ok?
    assert_equal '', last_response.body
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