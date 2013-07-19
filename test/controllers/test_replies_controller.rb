require_relative '../test_case'

class TestRepliesController < TestCase

  def self.before_suite
    @@reply_user = "test_reply_user"
    _delete_user
    @@user = LinkedData::Models::User.new(
      username: @@reply_user,
      email: "reply_user@example.org",
      password: "reply_user_pass"
    )
    @@user.save

    @@note = LinkedData::Models::Note.new({
      creator: @@user,
      subject: "Test subject note",
      body: "Test body for note"
    })
    @@note.save

    @@replies = []
    5.times do |i|
      reply = LinkedData::Models::Notes::Reply.new({
        creator: @@user,
        body: "Test body for reply #{i}"
      })
      reply.save
      @@replies << reply
      @@note.reply = (@@note.reply || []).dup.push(reply)
      @@note.save
    end
  end

  def self.after_suite
    @@note.delete
    _delete_user
  end

  def self._delete_user
    u = LinkedData::Models::User.find(@@reply_user).first
    u.delete unless u.nil?
  end

  def test_single_reply
    get "/notes/#{@@note.id.to_s.split('/').last}/replies"
    replies = MultiJson.load(last_response.body)
    reply = replies.first
    get reply['@id']
    assert last_response.ok?
    retrieved_reply = MultiJson.load(last_response.body)
    assert_equal reply["@id"], retrieved_reply["@id"]
  end

  def test_reply_lifecycle
    reply = {
      creator: @@user.id.to_s,
      body: "Testing body for reply",
      parent: @@note.id.to_s
    }
    post "/replies", MultiJson.dump(reply), "CONTENT_TYPE" => "application/json"
    assert last_response.status == 201

    new_reply = MultiJson.load(last_response.body)
    get new_reply["@id"]
    assert last_response.ok?

    reply_changes = {body: "New testing body"}
    patch new_reply["@id"], reply_changes.to_json, "CONTENT_TYPE" => "application/json"
    assert last_response.status == 204
    get new_reply["@id"]
    patched_reply = MultiJson.load(last_response.body)
    assert_equal patched_reply["body"], reply_changes[:body]

    delete new_reply["@id"]
    assert last_response.status == 204
  end

end