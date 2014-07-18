
module Bromo
  module Utils
    class Date

      # sun:0 mon:1 ... sat:6
      def self.next_x_day(key_num, start_time, to_time)

        now = Time.now

        y = now.year
        m = now.month
        d = now.day
        h = now.hour
        i = now.min
        s = now.sec

        rest_day = (7 - (now.wday - key_num)) % 7

        start_time = "0#{start_time}" if start_time.size == 3
        to_time = "0#{to_time}" if to_time.size == 3
        raise 'Not available Time string (format:"HHMM")' if start_time.size != 4 || to_time.size != 4

        ft = Time.mktime(y,m,d,0,0,0) +
          (rest_day * 60*60*24) + 
          (start_time[0,2].to_i * 60*60) +
          (start_time[2,2].to_i * 60)


        tt = Time.mktime(y,m,d,0,0,0) +
          (rest_day * 60*60*24) + 
          (to_time[0,2].to_i * 60*60) +
          (to_time[2,2].to_i * 60)

        return [ft,tt]

      end

      def self.today(start_time, to_time)
        self.next_x_day(Time.now.wday, start_time, to_time)
      end

    end
  end
end


