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
          notes.each do |note|
            recurse_replies(note.reply) unless note.reply.compact.empty?
          end
        elsif notes.first.is_a?(LinkedData::Models::Notes::Reply)
          notes = LinkedData::Models::Notes::Reply.where.models(notes).include(children: LinkedData::Models::Notes::Reply.goo_attrs_to_load).all
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
