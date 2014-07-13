
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

      def exsleep(time, original_sleep_only=false)

        return false if !Bromo::Core.running?
        return true if time < 0
        if @stopped
          @stopped = false
          return true
        end

        start = Time.now
        divided_sleep_time = 5

        if(divided_sleep_time >= time || original_sleep_only)
          sleep time
        else
          div = divided_sleep_time.to_i
          loop_num = time.to_i / div
          loop_num.times do
            break if !exsleep(div, true)
          end

          rest_time = Time.now - (start + time)
          exsleep(rest_time, true)

        end

        return true
      end

    end
  end
end

