
module Bromo
  class Recorder

    def self.run

      start_refresh_schedule
      start_check_queue

      sleep 5

      stop_refresh_schedule
      stop_check_queue

      @@refresh_schedule_thread.join if @@refresh_schedule_thread

    end

    @@refresh_schedule_thread = nil
    @@refresh_schedule_thread_flag = false
    def self.start_refresh_schedule
      @@refresh_schedule_thread_flag = false
      @@refresh_schedule_thread.join if @@refresh_schedule_thread

      @@refresh_schedule_thread_flag = true

      @@refresh_schedule_thread = Thread.new do

        Logger.debug("hoge")
        loop do
          Logger.debug(@@refresh_schedule_thread_flag)
          break if !@@refresh_schedule_thread_flag
          sleep 1
          p "hello 1"
        end
      end

    end

    @check_queue_thread = nil
    def self.start_check_queue

    end

    def self.stop_refresh_schedule
      @@refresh_schedule_thread_flag = false
    end
    def self.stop_check_queue
      @check_queue_thread_flag = false
    end



  end
end
