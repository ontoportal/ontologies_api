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
      ont_report = NcboCron::Models::OntologiesReport.new.ontologies_report(false)
      log_path = ont_report[:ontologies].has_key?(params["acronym"].to_sym) ? "#{LinkedData.settings.repository_folder}/#{ont_report[:ontologies][params["acronym"].to_sym][:logFilePath]}" : ''
      log_contents = ''

      if !log_path.empty? && File.file?(log_path)
        file = File.open(log_path, "rb")
        log_contents = file.read
        file.close
      end
      reply log_contents
    end

    put "/ontologies/:acronym" do
      actions = NcboCron::Models::OntologySubmissionParser::ACTIONS.dup
      actions[:all] = false
      error_message = "You must provide valid action(s) for ontology processing. Valid actions: ?actions=#{actions.keys.join(",")}"
      actions_param = params["actions"]
      error 404, error_message unless actions_param
      action_arr = actions_param.split(",")
      actions.each { |k, _| actions[k] = action_arr.include?(k.to_s) ? true : false }
      error 404, error_message if actions.values.select { |v| v === true }.empty?
      ont = Ontology.find(params["acronym"]).first
      error 404, "You must provide a valid `acronym` to retrieve an ontology" if ont.nil?
      ont.bring(:acronym, :submissions)
      latest = ont.latest_submission(status: :any)
      error 404, "Ontology #{params["acronym"]} contains no submissions" if latest.nil?
      check_last_modified(latest)
      latest.bring(*OntologySubmission.goo_attrs_to_load(includes_param))
      NcboCron::Models::OntologySubmissionParser.new.queue_submission(latest, actions)
      halt 204
    end

    get "/:acronym/latest_submission" do
      ont = Ontology.find(params["acronym"]).first
      error 404, "You must provide a valid `acronym` to retrieve an ontology" if ont.nil?
      include_status = params["include_status"]
      ont.bring(:acronym, :submissions)
      if include_status
        latest = ont.latest_submission(status: include_status.to_sym)
      else
        latest = ont.latest_submission(status: :any)
      end
      check_last_modified(latest) if latest
      latest.bring(*OntologySubmission.goo_attrs_to_load(includes_param)) if latest
      reply(latest || {})
    end

    get "/ontologies_report" do
      suppress_error = params["suppress_error"].eql?('true') # default = false
      reply NcboCron::Models::OntologiesReport.new.ontologies_report(suppress_error)
    end

    post "/ontologies_report" do
      ontologies = ontologies_param_to_acronyms(params)
      args = {name: "ontologies_report", message: "refreshing ontologies report"}
      process_id = process_long_operation(900, args) do |args|
        NcboCron::Models::OntologiesReport.new.refresh_report(ontologies)
      end
      reply(process_id: process_id)
    end

    get "/ontologies_report/:process_id" do
      process_id = MultiJson.load(redis.get(params["process_id"]))

      if process_id.nil?
        error 404, "Process id #{params["process_id"]} does not exit"
      else
        if process_id === "done"
          reply NcboCron::Models::OntologiesReport.new.ontologies_report(false)
        else
          # either "processing" OR errors {errors: ["errorA", "errorB"]}
          reply process_id
        end
      end
    end

    post "/clear_goo_cache" do
      redis_goo.flushdb
      halt 204
    end

    post "/clear_http_cache" do
      redis_http.flushdb
      halt 204
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
          msg = "Error #{args[:message]} - #{e.class}: #{e.message}"
          puts "#{msg}\n#{e.backtrace.join("\n\t")}"
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
      Redis.new(host: Annotator.settings.annotator_redis_host, port: Annotator.settings.annotator_redis_port, timeout: 30)
    end

    def redis_goo
      Redis.new(host: LinkedData.settings.goo_redis_host, port: LinkedData.settings.goo_redis_port, timeout: 30)
    end

    def redis_http
      Redis.new(host: LinkedData.settings.http_redis_host, port: LinkedData.settings.http_redis_port, timeout: 30)
    end

  end
end
