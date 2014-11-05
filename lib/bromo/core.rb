
require 'nokogiri'

module Bromo

  class Core
    # extend Concern

    attr_accessor :running
    attr_accessor :queue_manager, :queue_exsleep
    attr_accessor :schedule_updater, :schedule_exsleep

    def self.core
      @@core ||= self.new
    end

    def self.start

      Bromo.debug("start refresh")
      core.running = true
      Utils::Debug.insert_debug_schedule if Bromo.debug?
      core.queue_manager.clean_queue
      core.queue_manager.update_queue
      core.start_refresh_schedule
      core.start_check_queue
      core.start_server

      Bromo.debug("start loop")

      # main loop
      loop do
        sleep Bromo.debug? ? 1 : 5
        break if !Core.running?
      end

      Bromo.debug("shutdown...")
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
      Bromo.debug("core: initialize")
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
        ActiveRecord::Base.connection_pool.with_connection do
          Bromo.debug "start schedule thread"
          while Bromo.exsleep(schedule_updater.minimum_refresh_time_to_left) do
            break if !@refresh_schedule_thread_flag
            Bromo.debug("updater loop: schedule_updater.update")
            if schedule_updater.update
              Bromo.debug("updater loop: schedule_updater updated!")
              queue_manager.update_queue
              queue_exsleep.stop(true)
            end
          end
          Bromo.debug "end schedule thread"
        end
      end

    end

    def start_check_queue
      @check_queue_thread_flag = false
      @check_queue_thread.join if @check_queue_thread

      @check_queue_thread_flag = true

      Bromo.debug("create check thread")
      @check_queue_thread = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Bromo.debug "start queue thread"
          while queue_exsleep.exsleep(queue_manager.minimum_recording_time_to_left) do
            break if !@check_queue_thread_flag
            Bromo.debug("core: while loop record")
            queue_manager.update_queue
            queue_manager.record
          end
          Bromo.debug "end queue thread"
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

    def start_server
      @server_thread = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Bromo::Server.set :bind, Config.host
          Bromo::Server.set :port, Config.port
          Bromo::Server.set :signals, false
          Bromo::Server.set :traps, false
          Bromo::Server.set :options, {signals: false}
          Bromo::Server.run! do |server|
            if server.class.name == 'Thin::Server'
              # ignore signal trap in server
              server.instance_variable_set(:@setup_signals, false)
            end
          end

        end
      end
    end

    def stop_server
      Bromo::Server.quit!
      @server_thread.join if @server_thread
    end

  end
end
