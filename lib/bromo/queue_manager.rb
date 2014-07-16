module Bromo
  class QueueManager

    DEFAULT_WAIT_FOR_NEXT_RECORDING = 60*60

    @@medias = nil
    def self.medias
      @@medias ||= Config.media_names.map {|name|
        Bromo::Media.const_get(name.capitalize).new
      }
    end

    @@reservations = {}
    def self.add(key, &block)
      @@reservations[key] = block
    end
    def self.clear_reservation
      @@reservations = {}
    end

    def update_queue
      Bromo.debug("call update_queue")

      Model::Schedule.reset_queue!
      @@reservations.each do |key, res|
        Model::Schedule.create_queue(key,res)
      end

      queue.delete_if do |q|
        if q.recorded == Model::Schedule::RECORDED_RECORDED
          if q.thread.nil?
            true
          elsif q.thread.status == false
            Bromo.debug("remove thread = #{q.thread}")
            true
          elsif q.thread.status.nil?
            Bromo.debug("join and remove thread = #{q.thread}")
            q.thread.join
            true
          end
        end
      end
      new_queue = Model::Schedule.queue.where.not(id: queue.map(&:id))
      if new_queue
        @queue += new_queue
        Bromo.debug("Add new queue = #{new_queue.map(&:title)}, and queue.size = #{@queue.size}")
      end

    end

    def queue # not sorted
      @queue ||= Model::Schedule.queue.to_a
    end

    def recorded_queue
      queue.select do |q|
        q.recorded == Model::Schedule::RECORDED_QUEUE
      end.sort do |a,b|
        a.time_to_left <=> b.time_to_left
      end
    end

    def pop
      recorded_queue.first.tap do |q|
        if !q.nil?
          q.recorded = Model::Schedule::RECORDED_RECORDING
          q.save
        end
      end
    end

    def join_recording_thread
      queue.each do |q|
        Bromo.debug("join recording thread = #{q.thread}, of #{q.title}")
        if q.thread
          q.thread.join
          q.thread = nil
        end
      end
    end


    def record

      return if queue.empty?

      Bromo.debug("record: recorded_queue size = #{recorded_queue.size}")
      if recorded_queue.size > 0 && recorded_queue.first.from_time - Time.now.to_i < 10
        Bromo.debug("create recording thread pre")
        Thread.start(pop) do |s|
          Bromo.debug("create recording thread in poped s.id = #{s.id}")
          if !s.nil?
            s.thread = Thread.current
            Bromo.debug("recording thread = #{s.thread}")
            s.start_recording
            ActiveRecord::Base.connection.close
          end
        end
      end
    end

    def minimum_recording_time_to_left
      Bromo.debug("call minimum_recording_time_to_left")
      min = recorded_queue.first
      max = recorded_queue.last
      Bromo.debug("queue_manager: min.title = #{min.title}, time_to_left = #{min.time_to_left}") if min
      Bromo.debug("queue_manager: max.title = #{max.title}, time_to_left = #{max.time_to_left}") if max
      return min ? min.time_to_left : DEFAULT_WAIT_FOR_NEXT_RECORDING
    end

  end
end
