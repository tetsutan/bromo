require 'active_record'

module Bromo
  module Model
    class Schedule < ActiveRecord::Base

      RECORDED_NONE = 0
      RECORDED_QUEUE = 1
      RECORDED_RECORDING = 2
      RECORDED_RECORDED = 3
      RECORDED_FAILED = 4

      DEFAULT_GROUP_NAME = "default"

      attr_accessor :thread

      def media
        @media ||= QueueManager.medias.find do |m|
          m.name == self.module_name
        end
      end

      def start_recording
        Utils::Logger.logger.debug("Model.media = #{media.name}")
        if media.record(self)
          self.recorded = Model::Schedule::RECORDED_RECORDED
        else
          self.recorded = Model::Schedule::RECORDED_FAILED
        end
        self.save
      end


      def time_to_left
        self.from_time - Time.now.to_i
      end

      def save_since_finger_print_not_exist
        if !Model::Schedule.where(finger_print: self.finger_print).exists?
          save
        end
      end

      def self.create_queue(key, block)
        @@group_name = key || DEFAULT_GROUP_NAME
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
          res.group_name = @@group_name if @@group_name
          res.save
        end
      }


    end
  end
end
