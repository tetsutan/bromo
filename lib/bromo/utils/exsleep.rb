
require 'active_support/concern'

module Bromo
  module Utils
    module Exsleep

      extend ActiveSupport::Concern

      included do
        extend Exsleep
      end

      def exsleep(time, original_sleep_only=false)

        return false if !Bromo::Core.running?

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
          exsleep(div, true)

        end

        return true
      end

    end
  end
end

