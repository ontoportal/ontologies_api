require 'multi_json'

class AdminController < ApplicationController

  namespace "/admin" do
    before {
      if LinkedData.settings.enable_security && (!env["REMOTE_USER"] || !env["REMOTE_USER"].admin?)
        error 403, "Access denied"
      end
    }

    get "/objectspace" do
      GC.start
      gdb_objs = Hash.new 0
      ObjectSpace.each_object {|o| gdb_objs[o.class] += 1}
      obj_usage = gdb_objs.to_a.sort {|a,b| b[1]<=>a[1]}
      MultiJson.dump obj_usage
    end

    get "/ontologies_report" do
      refresh_ontologies_report if params["refresh"] === "true"
      reply raw_ontologies_report
    end

    get "/ontologies/:acronym/log" do
      ont = Ontology.find(params["acronym"]).first
      error 404, "Ontology #{params["acronym"]} does not exist" if ont.nil?
      ont.bring(:acronym, :submissions)
      latest = ont.latest_submission(status: :any)
      error 404, "No submissions found for ontology #{params["acronym"]}" if latest.nil?
      reply get_parse_log_file(latest)
    end

  end
end
