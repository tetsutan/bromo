require 'active_record'

module Bromo
  module Model
    class Schedule < ActiveRecord::Base

      RECORDED_NONE = 0
      RECORDED_QUEUE = 1
      RECORDED_RECORDING = 2
      RECORDED_RECORDED = 3

      def save_since_finger_print_not_exist
        if !Model::Schedule.where(finger_print: self.finger_print).exists?
          save
        end
      end

      def self.create_queue(block)
        class_eval &block
      end

      scope :queue, ->{
        where(recorded: RECORDED_QUEUE)
      }

      scope :order_by_time_to_left, -> {
        order("from_time ASC")
      }


      # use in .bromrc.rb
      scope :broadcaster, ->(name) {
        where(module_name: name)
      }
      scope :channel, ->(name){
        where(channel_name: name)
      }
      scope :search, ->(key){
        where("(title like '%#{key}%' OR description like '%#{key}%')")
      }

      DAYS = %w/sunday monday tuesday wednesday thursday friday saturday/
      scope :day, ->(day){
        term = Utils::Date.next_x_day(DAYS.index(day.to_s), "0000", "2359")

        # for SQLite
        where("from_time > ?", term[0].to_i). where("to_time < ?", term[1].to_i)
      }

      scope :reserve!, ->{
        where(recorded: RECORDED_NONE).each do |res|
          res.recorded = RECORDED_QUEUE
          res.save
        end
      }


    end
  end
end
