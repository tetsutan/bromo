module Bromo
  class ScheduleUpdater

    def update
      QueueManager.medias.any? do |m|
        m.update_schedule
      end
    end

    def minimum_refresh_time_to_left
      more_wait_for_check_need_update = 5
      QueueManager.medias.map(&:next_update).min - Time.now + more_wait_for_check_need_update
    end
  end
end
