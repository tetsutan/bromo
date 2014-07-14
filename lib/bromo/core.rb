
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
      core.insert_debug_schedule if Bromo.debug?
      core.queue_manager.update_queue
      core.start_refresh_schedule # FIXME uncomment
      core.start_check_queue
      core.start_server

      logger.debug("start loop")

      # main loop
      loop do
        sleep 5
        break if !Core.running?
      end

      logger.debug("shutdown...")
      core.stop_refresh_schedule
      core.stop_check_queue
      core.stop_server

    end

    def self.stop
      core.running = false
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

        Bromo.debug "start schedule thread"
        while schedule_updater.first_update? || Bromo.exsleep(schedule_updater.minimum_refresh_time_to_left) do
          break if !@refresh_schedule_thread_flag
          Bromo.debug("updater loop: schedule_updater.update")
          schedule_updater.update
          queue_manager.update_queue
          queue_exsleep.stop(true)
        end
        Bromo.debug "end schedule thread"
      end

    end

    def start_check_queue
      @check_queue_thread_flag = false
      @check_queue_thread.join if @check_queue_thread

      @check_queue_thread_flag = true

      logger.debug("create check thread")
      @check_queue_thread = Thread.new do

        Bromo.debug "start queue thread"
        while queue_exsleep.exsleep(2) do
          break if !@check_queue_thread_flag
          logger.debug("core: while loop record")
          queue_manager.update_queue
          queue_manager.record
        end
        Bromo.debug "end queue thread"
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

    def start_server
      @server_thread = Thread.new do
        Bromo::Server.run!
      end
    end

    def stop_server
      Bromo::Server.quit!
      @server_thread.join if @server_thread
    end

    def insert_debug_schedule

      now = Time.now.to_i
      logger.debug "insert_debug_schedule"

      Model::Schedule.destroy_all("title like '%BromoTest%'")

      schedule = Model::Schedule.new
      schedule.module_name = "radiko"
      schedule.channel_name = "LFR"
      schedule.title = "BromoTest"
      schedule.description = "Bromo Test Description"
      schedule.from_time = now + 10
      schedule.to_time = now + 40
      schedule.finger_print = schedule.module_name + schedule.channel_name + schedule.from_time.to_s
      schedule.save_since_finger_print_not_exist

      schedule = Model::Schedule.new
      schedule.module_name = "radiko"
      schedule.channel_name = "TBS"
      schedule.title = "BromoTest"
      schedule.description = "Bromo Test Description"
      schedule.from_time = now + 15
      schedule.to_time = now + 45
      schedule.finger_print = schedule.module_name + schedule.channel_name + schedule.from_time.to_s
      schedule.save_since_finger_print_not_exist

      100.times do |num|
        schedule = Model::Schedule.new
        schedule.module_name = "radiko"
        schedule.channel_name = "TBS"
        schedule.title = "BromoTest" + num.to_s
        schedule.description = "Bromo Test Description"
        schedule.from_time = now + 10 + num
        schedule.to_time = schedule.from_time + 5
        schedule.finger_print = schedule.module_name + schedule.channel_name + schedule.from_time.to_s
        schedule.save_since_finger_print_not_exist
      end

    end

  end
end
