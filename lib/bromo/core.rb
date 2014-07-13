
require 'nokogiri'

module Bromo

  class Core
    # extend Concern
    include Utils::Logger

    attr_accessor :running
    attr_accessor :queue_manager, :queue_exsleep
    attr_accessor :schedule_updater, :schedule_exsleep

    def self.core
      @@core ||= self.new
    end

    def self.start

      logger.debug("start refresh")
      core.running = true
      # core.start_refresh_schedule # FIXME uncomment

      core.insert_debug_schedule if Bromo.debug?

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
      self.schedule_exsleep = Utils::Exsleep.new
      self.queue_manager = QueueManager.new
      self.queue_exsleep = Utils::Exsleep.new
    end

    def start_refresh_schedule
      @refresh_schedule_thread_flag = false
      @refresh_schedule_thread.join if @refresh_schedule_thread

      @refresh_schedule_thread_flag = true

      @refresh_schedule_thread = Thread.new do

        while schedule_updater.first_update? || Bromo.exsleep(schedule_updater.minimum_refresh_time_to_left) do
          break if !@refresh_schedule_thread_flag
          Bromo.debug("updater loop: schedule_updater.update")
          schedule_updater.update
          queue_manager.update_queue
          queue_exsleep.stop
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

        while queue_exsleep.exsleep(queue_manager.minimum_recording_time_to_left) do
          break if !@check_queue_thread_flag
          logger.debug("core: while loop record")
          queue_manager.update_queue
          queue_manager.record
        end
      end


    end

    def stop_refresh_schedule
      @refresh_schedule_thread_flag = false
      schedule_exsleep.stop
      @refresh_schedule_thread.join if @refresh_schedule_thread
    end
    def stop_check_queue
      @check_queue_thread_flag = false
      queue_exsleep.stop
      @check_queue_thread.join if @check_queue_thread
      queue_manager.join_recording_thread
    end


    def insert_debug_schedule

      now = Time.now.to_i

      finger_print_lfr = "Bromo Test LFR Fingerprint"
      Model::Schedule.destroy_all(finger_print: finger_print_lfr)
      finger_print_tbs = "Bromo Test TBS Fingerprint"
      Model::Schedule.destroy_all(finger_print: finger_print_tbs)

      schedule = Model::Schedule.new
      schedule.module_name = "radiko"
      schedule.channel_name = "LFR"
      schedule.title = "Bromo Test LFR Title"
      schedule.description = "Bromo Test Description"
      schedule.from_time = now + 10
      schedule.to_time = now + 40
      schedule.finger_print = finger_print_lfr
      schedule.save_since_finger_print_not_exist

      schedule = Model::Schedule.new
      schedule.module_name = "radiko"
      schedule.channel_name = "TBS"
      schedule.title = "Bromo Test TBS Title"
      schedule.description = "Bromo Test Description"
      schedule.from_time = now + 15
      schedule.to_time = now + 45
      schedule.finger_print = finger_print_tbs
      schedule.save_since_finger_print_not_exist

      queue_exsleep.stop
    end

  end
end
