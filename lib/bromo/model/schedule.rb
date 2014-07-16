require 'active_record'
require 'digest/sha1'

module Bromo
  module Model
    class Schedule < ActiveRecord::Base

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

      scope :reset_queue!, ->{
        where(recorded: RECORDED_QUEUE).update_all(recorded: RECORDED_NONE)
      }

      scope :queue, ->{
        where(recorded: RECORDED_QUEUE).where("from_time > ?", Time.now.to_i)
      }

      scope :order_by_time_to_left, -> {
        order("from_time ASC")
      }

      scope :clear_before!, ->(media_name, time=60 * 60 * 24 * 14){
        where(media_name: media_name).
        where(recorded: RECORDED_RECORDED).
        where("from_time < ?", Time.now.to_i - time). # two weeks ago
        delete_all
      }


      # use in .bromrc.rb
      scope :media, ->(name) {
        where(media_name: name)
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

      scope :reserve!, ->(option = {}){
        where(recorded: RECORDED_NONE).each do |res|
          res.recorded = RECORDED_QUEUE
          res.group_name = @@group_name if @@group_name

          res.video = VIDEO_TRUE if option[:video]

          if option[:image]
            image = option[:image]
            image_url = image.is_a?(Proc) ? image.call : image.to_s
            if image_url.start_with?('http')
              # binary
              ext = image_url.split(".").last
              name = Digest::SHA1.hexdigest(image_url)
              file_name = "#{name}.#{ext}"
              file_path = File.join(Config.data_dir, "image", file_name)

              if !File.exist?(file_path)
                open(image_url) do |f_image|
                  open(File.join(Config.data_dir, "image", file_name), "w") do |f_dest|
                    f_dest.write(f_image.read)
                  end
                end
              end

              res.image_path = file_name
            end
          end


          res.save
        end
      }

      # use in server
      scope :recorded_by_group, ->(group_name) {
        where(group_name: group_name).where(recorded: RECORDED_RECORDED).order("to_time DESC")
      }

    end
  end
end
