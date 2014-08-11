require 'active_record'
require 'digest/sha1'

module Bromo
  module Model
    class Schedule < ActiveRecord::Base

      belongs_to :group

      before_save :create_search_text

      RECORDED_NONE = 0
      RECORDED_QUEUE = 1
      RECORDED_RECORDING = 2
      RECORDED_RECORDED = 3
      RECORDED_FAILED = 4

      VIDEO_FALSE = 0
      VIDEO_TRUE = 1

      DEFAULT_GROUP_NAME = "default"

      attr_accessor :thread

      def media
        @media ||= QueueManager.medias.find do |m|
          m.name == self.media_name
        end
      end

      def start_recording
        if !media
          self.recorded = RECORDED_FAILED
          self.save
        else
          file_name =  media.record(self)
          self.file_path = file_name
          if file_name
            self.recorded = RECORDED_RECORDED
          else
            self.recorded = RECORDED_FAILED
          end

          self.save
        end

      end


      def time_to_left
        self.from_time - Time.now.to_i
      end

      def end_time_to_left
        if self.to_time
          self.to_time - Time.now.to_i
        else
          0
        end
      end

      def save_since_finger_print_not_exist
        if !Model::Schedule.where(finger_print: self.finger_print).exists?
          save
        end
      end

      def video?
        self.video == VIDEO_TRUE
      end

      def self.create_queue(key, block)
        @@group_name = key || DEFAULT_GROUP_NAME
        class_eval &block
      end

      def create_search_text
        self.search_text = Utils.normalize_search_text("#{self.title} #{self.description}")
      end


      def self.reset_queue!
        where(recorded: RECORDED_QUEUE).update_all(recorded: RECORDED_NONE)

        # Re-Recoding if now on air, else failed
        where(recorded: RECORDED_RECORDING).now_on_air.update_all(recorded: RECORDED_NONE)
        where(recorded: RECORDED_RECORDING).update_all(recorded: RECORDED_FAILED)
      end

      scope :queue, ->{
        where(recorded: RECORDED_QUEUE).where("from_time > ?", Time.now.to_i)
      }

      scope :order_by_time_to_left, -> {
        order("from_time ASC")
      }

      def self.clear_before!(media_name, time=60 * 60 * 24 * 14)
        where(media_name: media_name).
        where(recorded: RECORDED_RECORDED).
        where("from_time < ?", Time.now.to_i - time). # two weeks ago
        delete_all
      end

      # use in .bromrc.rb
      scope :media, ->(name) {
        where(media_name: name)
      }
      scope :channel, ->(name){
        where(channel_name: name)
      }
      scope :search, ->(key){
        where("search_text like ?", "%#{Utils.normalize_search_text(key)}%")
      }

      DAYS = %w/sunday monday tuesday wednesday thursday friday saturday/
      scope :day, ->(day){
        term = Utils::Date.next_x_day(DAYS.index(day.to_s), "0000", "2359")
        where("from_time > ? and from_time < ?", term[0].to_i, term[1].to_i)
      }
      scope :time_after, ->(day, time){
        term = Utils::Date.next_x_day(DAYS.index(day.to_s), time, "2359")
        where("from_time >= ? and from_time <= ?", term[0].to_i, term[1].to_i)
      }
      scope :time_before, ->(day, time){
        term = Utils::Date.next_x_day(DAYS.index(day.to_s), "0000", time)
        where("from_time >= ? and from_time <= ?", term[0].to_i, term[1].to_i)
      }
      scope :time_between, ->(day, time_a, time_b){
        term = Utils::Date.next_x_day(DAYS.index(day.to_s), time_a, time_b)
        where("from_time >= ? and from_time <= ?", term[0].to_i, term[1].to_i)
      }

      # FIXME move to method, but reserve! is called from ActiveRecord::Relation
      scope :reserve!, ->(option = {}){
        now = Time.now
        where(recorded: RECORDED_NONE).each do |res|
          next if res.media && res.media.realtime? && res.to_time < now.to_i

          res.recorded = RECORDED_QUEUE
          if @@group_name
            res.group = Group.find_or_create_by(name: @@group_name)
          end

          res.video = VIDEO_TRUE if option[:video]

          if option[:image]
            image = option[:image]
            image_url = image.is_a?(Proc) ? image.call : image.to_s
            res.image_path = Bromo::Utils.save_image(image_url)
          end

          res.save
        end
      }

      def self.image!(url=nil, &block)
        image_url = block_given? ? block.call : url
        if image_url && @@group_name
          Group.find_or_create_by(name: @@group_name).tap do |group|
            new_image_path = Bromo::Utils.save_image(image_url)
            if group.image_path != new_image_path
              group.image_path = new_image_path
              group.save
            end
          end
        end
      end

      # use in server
      scope :recorded_by_group, ->(group) {
        where(group: group).where(recorded: RECORDED_RECORDED).order("to_time DESC")
      }
      scope :recorded, ->{
        where(recorded: RECORDED_RECORDED)
      }
      scope :recording, ->{
        where(recorded: RECORDED_RECORDING)
      }
      scope :queue, ->{
        where(recorded: RECORDED_QUEUE)
      }
      scope :failed, ->{
        where(recorded: RECORDED_FAILED)
      }
      scope :now_on_air, ->{
        where("from_time < ?", Time.now.to_i).
        where("to_time > ?", Time.now.to_i)
      }
      scope :from_time_desc, ->{
        order("from_time DESC")
      }
      scope :from_time_asc, ->{
        order("from_time ASC")
      }
      scope :to_time_desc, ->{
        order("to_time DESC")
      }
      scope :to_time_asc, ->{
        order("to_time ASC")
      }

    end
  end
end
