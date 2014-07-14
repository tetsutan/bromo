
require 'active_support/concern'

module Bromo
  module Utils
    class Exsleep

      def initialize
        @stopped = false
      end

      def stop
        @stopped = true
      end

      def exsleep(time, original_sleep_only=false, root = true)

        Bromo.debug("exsleep #{time}") if root

        return false if !Bromo::Core.running?
        return true if time < 0
        return false if @stopped

        flag = true

        start = Time.now
        divided_sleep_time = 5

        if(divided_sleep_time >= time || original_sleep_only)
          sleep time
        else
          div = divided_sleep_time.to_i
          loop_num = time.to_i / div
          loop_num.times do
            if !exsleep(div, true, false)
              flag = false
              break
            end
          end

          if flag
            rest_time = Time.now - (start + time)
            flag = exsleep(rest_time, true, false)
          end

        end

        Bromo.debug("exsleep cancel") if root && !flag
        return flag
      end

    end
  end
end

