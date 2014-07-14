
module Bromo
  module Utils
    class Debug

      def self.insert_debug_schedule

        Bromo.debug "insert_debug_schedule"

        Model::Schedule.destroy_all("title like '%BromoTest%'")

        new.insert

      end

      def insert
        insert_radiko
        insert_ag
      end


      def now
        @now ||= Time.now.to_i
      end

      def insert_radiko

        schedule = Model::Schedule.new
        schedule.media_name = "radiko"
        schedule.channel_name = "LFR"
        schedule.title = "BromoTest Radiko LFR"
        schedule.description = "Bromo Test Description"
        schedule.from_time = now + 10
        schedule.to_time = schedule.from_time + 30
        schedule.finger_print = schedule.media_name + schedule.channel_name + schedule.from_time.to_s
        schedule.save_since_finger_print_not_exist

        schedule = Model::Schedule.new
        schedule.media_name = "radiko"
        schedule.channel_name = "TBS"
        schedule.title = "BromoTest Raiko TBS"
        schedule.description = "Bromo Test Description"
        schedule.from_time = now + 15
        schedule.to_time = schedule.from_time + 30
        schedule.finger_print = schedule.media_name + schedule.channel_name + schedule.from_time.to_s
        schedule.save_since_finger_print_not_exist

        # 100.times do |num|
        #   schedule = Model::Schedule.new
        #   schedule.media_name = "radiko"
        #   schedule.channel_name = "TBS"
        #   schedule.title = "BromoTest" + num.to_s
        #   schedule.description = "Bromo Test Description"
        #   schedule.from_time = now + 10 + num
        #   schedule.to_time = schedule.from_time + 5
        #   schedule.finger_print = schedule.media_name + schedule.channel_name + schedule.from_time.to_s
        #   schedule.save_since_finger_print_not_exist
        # end

      end

      def insert_ag

        schedule = Model::Schedule.new
        schedule.media_name = "ag"
        schedule.channel_name = ""
        schedule.title = "BromoTest Ag 1"
        schedule.description = "Bromo Test Description"
        schedule.from_time = now + 10
        schedule.to_time = schedule.from_time + 30
        schedule.finger_print = schedule.media_name + schedule.channel_name + schedule.from_time.to_s
        schedule.save_since_finger_print_not_exist

        # schedule = Model::Schedule.new
        # schedule.media_name = "ag"
        # schedule.channel_name = ""
        # schedule.title = "BromoTest Ag 2"
        # schedule.description = "Bromo Test Description"
        # schedule.from_time = now + 30
        # schedule.to_time = schedule.from_time + (60 * 5)
        # schedule.finger_print = schedule.media_name + schedule.channel_name + schedule.from_time.to_s
        # schedule.save_since_finger_print_not_exist

        # schedule = Model::Schedule.new
        # schedule.media_name = "ag"
        # schedule.channel_name = ""
        # schedule.title = "BromoTest Ag 3"
        # schedule.description = "Bromo Test Description"
        # schedule.from_time = now + (60*5) - 5
        # schedule.to_time = schedule.from_time + (60 * 5)
        # schedule.finger_print = schedule.media_name + schedule.channel_name + schedule.from_time.to_s
        # schedule.save_since_finger_print_not_exist

      end
    end
  end
end
