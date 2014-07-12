

module Bromo

  class Core
    # extend Concern
    include Utils::Logger
    include Utils::Exsleep

    attr_accessor :running
    attr_accessor :queue_manager
    attr_accessor :schedule_updater

    def self.core
      @@core ||= self.new
    end

    def self.start

      logger.debug("start refresh")
      core.running = true
      # core.start_refresh_schedule # FIXME uncommented out
      core.start_check_queue

    end

    def self.stop

      logger.debug("stop refresh")
      core.running = false
      logger.debug("stop refresh: schedule")
      core.stop_refresh_schedule
      logger.debug("stop refresh: queue")
      core.stop_check_queue

    end

    def self.running?
      core.running
    end

    def initialize
      logger.debug("core: initialize")
      self.schedule_updater = ScheduleUpdater.new
      self.queue_manager = QueueManager.new
    end

    def start_refresh_schedule
      @refresh_schedule_thread_flag = false
      @refresh_schedule_thread.join if @refresh_schedule_thread

      @refresh_schedule_thread_flag = true

      @refresh_schedule_thread = Thread.new do

        while schedule_updater.first_update? || exsleep(schedule_updater.minimum_refresh_time_to_left) do
          break if !@refresh_schedule_thread_flag
          schedule_updater.update
          queue_manager.update_queue
        end
      end

    end

    def start_check_queue
      @check_queue_thread_flag = false
      @check_queue_thread.join if @check_queue_thread

      @check_queue_thread_flag = true

      logger.debug("create check thread")
      @check_queue_thread = Thread.new do

        logger.debug("do check thread run loop")

        # FIXME REMOVEME
        logger.debug("for DEBUG: no wait")
          queue_manager.update_queue
          logger.debug("for DEBUG: queue = #{queue_manager.queue}")
          queue_manager.record

        while exsleep(queue_manager.minimum_recording_time_to_left) do
          break if !@check_queue_thread_flag
          queue_manager.update_queue
          queue_manager.record
        end
      end


    end

    def stop_refresh_schedule
      @refresh_schedule_thread_flag = false
      @refresh_schedule_thread.join if @refresh_schedule_thread
    end
    def stop_check_queue
      @check_queue_thread_flag = false
      @check_queue_thread.join if @check_queue_thread
      queue_manager.join_recording_thread
    end



  end
end
