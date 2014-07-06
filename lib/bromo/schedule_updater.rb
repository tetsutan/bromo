module Bromo
  class ScheduleUpdater

    def update

      Manager.medias.each do |m|
        m.update_schedule
      end



      # REMOVEME DEBUG
      sleep 5

      @last_updated_at = Time.now
    end

    def first_update?
      @last_updated_at.nil?
    end

    def minimum_refresh_time_to_left
      Manager.medias.map(&:refresh_time_since).min - Time.now
    end
  end
end
