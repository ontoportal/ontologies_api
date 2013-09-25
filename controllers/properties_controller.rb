class PropertiesController < ApplicationController

  namespace "/ontologies/:ontology/properties" do
    get '/:property/label' do 
      expires 86400, :public
      ont, submission = get_ontology_and_submission
      query_label = <<eso
SELECT * 
FROM #{submission.id.to_ntriples}
WHERE {
<#{params[:property]}> <http://www.w3.org/2000/01/rdf-schema#label> ?label }
 LIMIT 1
eso
      epr = Goo.sparql_query_client(:main)
      label = nil
      graphs = [submission.id]
      epr.query(query_label, graphs: graphs, query_options: {rules: :NONE}).each do |sol|
        label = sol[:label].object
      end
      reply({ label: label })
    end
  end

end
