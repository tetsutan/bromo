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
      @queue = Model::Schedule.queue
    end

    def queue
      @queue ||= Model::Schedule.queue
    end


    def record

    end

    def minimum_recording_time_to_left
      queue.order_by_time_to_left.first.from_time - Time.now.to_i
    end

  end
end
