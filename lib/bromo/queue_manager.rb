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
      @@reservations.values.map do |res|
        Model::Schedule.create_queue(res)
      end
      @queue = Model::Schedule.queue.to_a
    end

    def queue
      @queue ||= Model::Schedule.queue.to_a
    end

    def join_recording_thread
      queue.each do |q|
        Utils::Logger.logger.debug("join recording thread = #{q.thread}")
        if q.thread
          q.thread.join
          q.thread = nil
        end
      end
    end


    def record

      return if queue.empty?

      # if queue.first.from_time - Time.now.to_i < 10
      Utils::Logger.logger.debug("record: queue size = #{queue.size}")
      if queue.first.from_time - Time.now.to_i < 10000000000
        current = queue.pop
        current.recorded = Model::Schedule::RECORDED_RECORDING
        current.save
        Utils::Logger.logger.debug("create recording thread pre")
        Thread.start(current) do |s|
          Utils::Logger.logger.debug("create recording thread in")
          s.thread = Thread.current
          Utils::Logger.logger.debug("recording thread = #{s.thread}")
          if s.record
            s.recorded = Model::Schedule::RECORDED_RECORDED
          else
            s.recorded = Model::Schedule::RECORDED_FAILED
          end
          s.save
          s.thread = nil
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
