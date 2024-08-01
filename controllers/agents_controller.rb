class AgentsController < ApplicationController

  get '/ontologies/:acronym/agents' do
    ont = Ontology.find(params["acronym"]).first
    latest = ont.latest_submission(status: :any)
    latest.bring(*OntologySubmission.agents_attrs)
    properties_agents= {}
    OntologySubmission.agents_attrs.each do |attr|
      properties_agents[attr] = Array(latest.send(attr))
    end

    agents =  []
    properties_agents.each do |key, value|
      agents.concat(value.map{ |agent| agent.bring_remaining})
    end
    agents.uniq!

    if includes_param.include?(:all) || includes_param.include?(:usages)
      LinkedData::Models::Agent.load_agents_usages(agents)
    end

    reply agents
  end

  %w[agents Agents].each do |namespace|
    namespace "/#{namespace}" do
      get do
        check_last_modified_collection(LinkedData::Models::Agent)
        query = LinkedData::Models::Agent.where
        query = apply_filters(LinkedData::Models::Agent, query)
        query = query.include(LinkedData::Models::Agent.goo_attrs_to_load(includes_param))
        if page?
          page, size = page_params
          agents = query.page(page, size).all
        else
          agents = query.to_a
        end

        if includes_param.include?(:all) || includes_param.include?(:usages)
          LinkedData::Models::Agent.load_agents_usages(agents)
        end

        reply agents
      end

      # Display a single agent
      get '/:id' do
        check_last_modified_collection(LinkedData::Models::Agent)
        id = params["id"]
        agent = LinkedData::Models::Agent.find(id).include(LinkedData::Models::Agent.goo_attrs_to_load(includes_param)).first
        error 404, "Agent #{id} not found" if agent.nil?
        reply 200, agent
      end

      # Create a agent with the given acronym
      post do
        reply 201, create_new_agent
      end

      # Create a agent with the given acronym
      put '/:acronym' do
        reply 201, create_new_agent
      end

      # Update an existing submission of a agent
      patch '/:id' do
        acronym = params["id"]
        agent = LinkedData::Models::Agent.find(acronym).include(LinkedData::Models::Agent.attributes).first

        if agent.nil?
          error 400, "Agent does not exist, please create using HTTP PUT before modifying"
        else
          agent = update_agent(agent, params)

          error 400, agent.errors unless agent.errors.empty?
        end
        halt 204
      end

      # Delete a agent
      delete '/:id' do
        agent = LinkedData::Models::Agent.find(params["id"]).first
        agent.delete
        halt 204
      end

      private

      def update_identifiers(identifiers)
        Array(identifiers).map do |i|
          next nil if i.empty?

          id =  i["id"] || LinkedData::Models::AgentIdentifier.generate_identifier(i['notation'], i['schemaAgency'])
          identifier = LinkedData::Models::AgentIdentifier.find(RDF::URI.new(id)).first

          if identifier
            identifier.bring_remaining
          else
            identifier = LinkedData::Models::AgentIdentifier.new
          end

          i.delete "id"

          next identifier if i.keys.size.zero?

          populate_from_params(identifier, i)

          if identifier.valid?
            identifier.save
          else
            error 400, identifier.errors
          end
          identifier
        end.compact
      end

      def update_affiliations(affiliations)
        Array(affiliations).map do |aff|
          affiliation =  aff["id"] ? LinkedData::Models::Agent.find(RDF::URI.new(aff["id"])).first : nil

          if affiliation
            affiliation.bring_remaining
            affiliation.identifiers.each{|i| i.bring_remaining}
          end

          next affiliation if aff.keys.size.eql?(1) && aff["id"]

          if affiliation
            affiliation = update_agent(affiliation, aff)
          else
            affiliation = create_new_agent(aff["id"], aff)
          end

          error 400, affiliation.errors unless affiliation.errors.empty?

          affiliation
        end
      end

      def create_new_agent (id = @params['id'], params = @params)
        agent = nil
        agent = LinkedData::Models::Agent.find(id).include(LinkedData::Models::Agent.goo_attrs_to_load(includes_param)).first if id

        if agent.nil?
          agent = update_agent(LinkedData::Models::Agent.new, params)
          error 400, agent.errors unless agent.errors.empty?

          return agent
        else
          error 400, "Agent exists, please use HTTP PATCH to update"
        end
      end

      def update_agent(agent, params)
        return agent unless agent

        identifiers = params.delete "identifiers"
        affiliations = params.delete "affiliations"
        params.delete "id"
        populate_from_params(agent, params)
        agent.identifiers = update_identifiers(identifiers)
        agent.affiliations = update_affiliations(affiliations)

        agent.save if agent.valid?
        return agent
      end

    end
  end

end
