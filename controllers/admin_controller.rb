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

    get "/report" do
      reply ontologies_report
    end

    get "/problem_ontologies" do
      report = ontologies_report
      report.each do |acronym, rpt|
        if (rpt["problem"] === false)
          report.delete acronym
        else
          rpt.delete_if {|k, v| k === "problem"}
        end
      end

      reply report
    end

    def ontologies_report
      report_path = NcboCron.settings.ontology_report_path

      if report_path.nil? or report_path.length == 0
        reply({ error: "Ontologies report path not set in config" })
      end
      if !File.exist?(report_path)
        reply({ error: "file #{report_path} not found"})
      end
      json_string = IO.read(report_path)
      report = JSON.parse(json_string)
      report.each {|acronym, rpt| rpt["uri"] = ontology_uri_from_acronym(acronym)}
      report
    end

  end
end
