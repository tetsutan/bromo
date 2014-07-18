module Bromo
  class ScheduleUpdater

    def update
      # QueueManager.medias.any? can not update two or more
      QueueManager.medias.map { |m|
        m.update_schedule
      }.any?
    end

    def minimum_refresh_time_to_left
      more_wait_for_check_need_update = 5
      QueueManager.medias.map(&:next_update).min - Time.now + more_wait_for_check_need_update
    end
  end
end
