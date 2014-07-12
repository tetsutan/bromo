module Bromo
  class QueueManager

    @@medias = nil
    def self.medias
      @@medias ||= Config.broadcaster_names.map {|name|

        class_name = name.capitalize
        klass = Bromo::Media.const_get(class_name)
        klass.new

      }
    end

    @@reservations = {}
    def self.add(key, &block)
      @@reservations[key] = block
    end

    def update_queue
      Utils::Logger.logger.debug("call update_queue")

      @@reservations.values.map do |res|
        Model::Schedule.create_queue(res)
      end

      queue.delete_if do |q|
        if q.recorded == Model::Schedule::RECORDED_RECORDING
          if q.thread.nil?
            Utils::Logger.logger.debug("remove thread1 = #{q.thread}")
            true
          elsif q.thread.status == false
            Utils::Logger.logger.debug("remove thread2 = #{q.thread}")
            true
          elsif q.thread.status.nil?
            Utils::Logger.logger.debug("remove thread3 = #{q.thread}")
            q.thread.join
            true
          end
        end
      end
      new_queue = Model::Schedule.queue.where.not(id: queue.map(&:id))
      if new_queue
        @queue += new_queue
        Utils::Logger.logger.debug("Add new queue = #{new_queue.map(&:title)}, and queue.size = #{@queue.size}")
      end

    end

    def queue
      @queue ||= Model::Schedule.queue.to_a
    end

    def pop
      queue.detect do |q|
        q.recorded == Model::Schedule::RECORDED_QUEUE
      end.tap do |q|
        if !q.nil?
          q.recorded = Model::Schedule::RECORDED_RECORDING
          q.save
        end
      end
    end

    def join_recording_thread
      queue.each do |q|
        Utils::Logger.logger.debug("join recording thread = #{q.thread}, of #{q.title}")
        if q.thread
          q.thread.join
          q.thread = nil
        end
      end
    end


    def record

      return if queue.empty?

      Utils::Logger.logger.debug("record: queue size = #{queue.size}")
      # TODO Switch
      # if queue.first.from_time - Time.now.to_i < 10
      if queue.first.from_time - Time.now.to_i < 10000000000
        Utils::Logger.logger.debug("create recording thread pre")
        Thread.start(pop) do |s|
          Utils::Logger.logger.debug("create recording thread in poped = #{s}")
          if !s.nil?
            s.thread = Thread.current
            Utils::Logger.logger.debug("recording thread = #{s.thread}")
            s.start_recording
          end
        end
      end
    end

    def minimum_recording_time_to_left
      min = queue.first
      if min
        min.time_to_left
      else
        60 * 60
      end
    end

  end
end
