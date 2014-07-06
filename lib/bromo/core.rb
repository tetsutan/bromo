

module Bromo

  class Core
    # extend Concern
    include Utils::Logger
    include Utils::Exsleep

    attr_accessor :running
    attr_accessor :schedule_updater

    def self.core
      @@core ||= self.new
    end

    def self.start

      logger.debug("start refresh")
      core.running = true
      core.start_refresh_schedule
      core.start_check_queue

    end

    def self.stop

      logger.debug("stop refresh")
      core.running = false
      core.stop_refresh_schedule
      core.stop_check_queue

    end

    def self.running?
      core.running
    end

    def initialize
      logger.debug("core: initialize")
      self.schedule_updater = ScheduleUpdater.new
    end

    def start_refresh_schedule
      @refresh_schedule_thread_flag = false
      @refresh_schedule_thread.join if @refresh_schedule_thread

      @refresh_schedule_thread_flag = true

      @refresh_schedule_thread = Thread.new do

        while schedule_updater.first_update? || exsleep(schedule_updater.minimum_refresh_time_to_left) do
          break if !@refresh_schedule_thread_flag
          schedule_updater.update
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
