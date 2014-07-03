

module Bromo

  class Recorder
    # extend Concern
    include Utils::Logger
    include Utils::Exsleep

    attr_accessor :running

    def self.recorder
      @@recorder ||= self.new
    end

    def self.start

      logger.debug("start refresh")
      recorder.running = true
      recorder.start_refresh_schedule
      recorder.start_check_queue

    end

    def self.stop

      logger.debug("stop refresh")
      recorder.running = false
      recorder.stop_refresh_schedule
      recorder.stop_check_queue

    end

    def self.running?
      recorder.running
    end

    def start_refresh_schedule
      @refresh_schedule_thread_flag = false
      @refresh_schedule_thread.join if @refresh_schedule_thread

      @refresh_schedule_thread_flag = true

      @refresh_schedule_thread = Thread.new do

        while exsleep(3) do
          break if !@refresh_schedule_thread_flag

          Config.broadcaster_names

          p "hello 1"

        end
      end

    end

    @check_queue_thread = nil
    def start_check_queue

    end

    def stop_refresh_schedule
      @refresh_schedule_thread_flag = false
      @refresh_schedule_thread.join if @refresh_schedule_thread
    end
    def stop_check_queue
      @check_queue_thread_flag = false
    end



  end
end
