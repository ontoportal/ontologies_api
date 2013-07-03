class RepliesController < ApplicationController

  # Display all replies for a note
  get "/notes/:noteid/replies" do
    noteid = LinkedData::Models::Note.id_prefix + params["noteid"]
    note = LinkedData::Models::Note.find(RDF::IRI.new(noteid)).include(:reply).first
    error 404, "Note `#{noteid}` not found" if note.nil?
    reply note.reply
  end

  namespace "/replies" do
    # Display a single reply
    get "/:replyid" do
      reply_query = LinkedData::Models::Notes::Reply.find(params["replyid"])
      reply_query = reply_query.include(LinkedData::Models::Notes::Reply.goo_attrs_to_load(includes_param))
      _reply = reply_query.first
      error 404, "Reply #{replyid} not found" if _reply.nil?
      reply 200, _reply
    end

    # Create a reply with the given noteid
    post do
      noteid = params["note"]
      note = LinkedData::Models::Note.find(RDF::IRI.new(noteid)).include(LinkedData::Models::Note.attributes).first

      _reply = instance_from_params(LinkedData::Models::Notes::Reply, params)

      unless note || _reply.parent
        error 422, "You must provide either a `note` or a `parent` to associate the reply with"
      end

      if _reply.valid?
        _reply.save
        if note
          begin
            note.reply = note.reply.dup.push(_reply)
            note.save
          rescue
            _reply.delete
            error 400, note.errors
          end
        end
      else
        error 400, _reply.errors
      end
      reply 201, _reply
    end

    # Update an existing submission of an reply
    patch '/:replyid' do
      replyid = params["replyid"]
      _reply = LinkedData::Models::Notes::Reply.find(replyid).include(LinkedData::Models::Notes::Reply.attributes).first

      if _reply.nil?
        error 400, "Reply does not exist, please create using HTTP POST before modifying"
      else
        populate_from_params(_reply, params)

        if _reply.valid?
          _reply.save
        else
          error 400, _reply.errors
        end
      end
      halt 204
    end

    # Delete a reply
    delete '/:replyid' do
      _reply = LinkedData::Models::Notes::Reply.find(params["replyid"]).first
      _reply.delete
      halt 204
    end
  end
end