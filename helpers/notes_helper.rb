
require 'sinatra/base'

module Sinatra
  module Helpers
    module NotesHelper

      ##
      # Go through notes and recurse the replies, replacing ids with actual reply objects
      def recurse_replies(notes)
        return if notes.nil?
        notes = notes.is_a?(Array) ? notes : [notes]
        if notes.first.is_a?(LinkedData::Models::Note)
          notes = LinkedData::Models::Note.where.models(notes).include(reply: LinkedData::Models::Note.goo_attrs_to_load).all
          notes.each do |note|
            # Handle notes
            if !note.reply.compact.empty?
              note.reply.each do |reply|
                # reply = LinkedData::Models::Notes::Reply.find(reply.to_s).first
                reply.bring_remaining
                recurse_replies(reply)
              end
            end
          end
        elsif notes.first.is_a?(LinkedData::Models::Notes::Reply)
          notes = LinkedData::Models::Notes::Reply.where.models(notes).include(*([:children] + LinkedData::Models::Note.goo_attrs_to_load)).all
          notes.each do |note|
            recurse_replies(note.children)
          end
        end
        notes
      end

    end
  end
end

helpers Sinatra::Helpers::NotesHelper
