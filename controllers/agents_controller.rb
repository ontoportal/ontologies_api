class AgentsController < ApplicationController

  %w[/agents /Agents].each do |namespace|
    namespace namespace do
      # Display all agents
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
        create_agent
      end

      # Create a agent with the given acronym
      put '/:acronym' do
        create_agent
      end

      # Update an existing submission of a agent
      patch '/:id' do
        acronym = params["id"]
        agent = LinkedData::Models::Agent.find(acronym).include(LinkedData::Models::Agent.attributes).first

        if agent.nil?
          error 400, "Agent does not exist, please create using HTTP PUT before modifying"
        else
          populate_from_params(agent, params)

          if agent.valid?
            agent.save
          else
            error 400, agent.errors
          end
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

      def create_agent
        params ||= @params
        acronym = params["id"]
        agent = nil
        agent = LinkedData::Models::Agent.find(acronym).include(LinkedData::Models::Agent.goo_attrs_to_load(includes_param)).first if acronym

        if agent.nil?
          agent = instance_from_params(LinkedData::Models::Agent, params)
        else
          error 400, "Agent exists, please use HTTP PATCH to update"
        end

        if agent.valid?
          agent.save
        else
          error 400, agent.errors
        end
        reply 201, agent
      end

    end
  end

end