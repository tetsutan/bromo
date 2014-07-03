module Bromo
  class ScheduleUpdater

    def update

      Config.broadcaster_names.each do |broadcaster_name|

      end

      # REMOVEME DEBUG
      sleep 5

      @last_updated_at = Time.now
    end

    def first_update?
      @last_updated_at.nil?
    end


  end
end
