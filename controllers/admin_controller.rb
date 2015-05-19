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

    get "/ontologies/:acronym/log" do
      ont = Ontology.find(params["acronym"]).first
      error 404, "Ontology #{params["acronym"]} does not exist" if ont.nil?
      ont.bring(:acronym, :submissions)
      latest = ont.latest_submission(status: :any)
      error 404, "No submissions found for ontology #{params["acronym"]}" if latest.nil?
      reply get_parse_log_file(latest)
    end

    get "/ontologies_report" do
      suppress_error = params["suppress_error"].eql?('true') # default = false
      reply raw_ontologies_report(suppress_error)
    end

    post "/ontologies_report" do
      args = {name: "ontologies_report", message: "refreshing ontologies report"}
      process_id = process_long_operation(900, args) do |args|
        refresh_ontologies_report
      end
      reply(process_id: process_id)
    end

    get "/ontologies_report/:process_id" do
      process_id = MultiJson.load(redis.get(params["process_id"]))

      if process_id.nil?
        error 404, "Process id #{params["process_id"]} does not exit"
      else
        if process_id === "done"
          reply raw_ontologies_report(false)
        else
          # either "processing" OR errors {errors: ["errorA", "errorB"]}
          reply process_id
        end
      end
    end

    private

    def process_long_operation(timeout, args)
      process_id = "#{Time.now.to_i}_#{args[:name]}"
      redis.setex process_id, timeout, MultiJson.dump("processing")
      proc = Proc.new {
        error = {}
        begin
          yield(args)
        rescue Exception => e
          msg = "Error #{args[:message]}: #{e.message}"
          puts msg
          error[:errors] = [msg]
        end
        redis.setex process_id, timeout, MultiJson.dump(error.empty? ? "done" : error)
      }

      fork = true # set to false for testing
      if fork
        pid = Process.fork do
          proc.call
        end
        Process.detach(pid)
      else
        proc.call
      end
      process_id
    end

    def redis
      Redis.new(host: Annotator.settings.annotator_redis_host, port: Annotator.settings.annotator_redis_port)
    end
  end
end
