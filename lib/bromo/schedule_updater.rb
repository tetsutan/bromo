module Bromo
  class ScheduleUpdater

    def update

      QueueManager.medias.each do |m|
        m.update_schedule
      end

      @last_updated_at = Time.now
    end

    def first_update?
      @last_updated_at.nil?
    end

    def minimum_refresh_time_to_left
      QueueManager.medias.map(&:refresh_time_since).min - Time.now
    end
  end
end
