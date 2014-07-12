module Bromo
  module Media
    class Radiko
      include Base

      realtime :true
      recording_delay_for_realtime 20

      def clean_db
        clear_before(:two_weeks)
      end

      def update_db
        # weekly
        area_id = "JP13" # default: Tokyo
        now = Time.now.to_i
        get_station_ids_with_url("http://radiko.jp/v2/station/list/#{area_id}.xml?_=#{now}").each do |station_id|
          update_weekly_program_with_url("http://radiko.jp/v2/api/program/station/weekly?station_id=#{station_id}&_=#{now}")
        end
      end

      def get_station_ids_with_url(url)
        open(url) do |f|
          doc = Nokogiri::XML(f.read)
          return doc.xpath('//stations/station/id').map do |s|
            s.text
          end
        end
      end

      def update_weekly_program_with_url(url)
        open(url) do |f|
          doc = Nokogiri::XML(f.read)
          doc.xpath('//radiko/stations/station').each do |s|
            ch_id = s['id']
            s.xpath('scd/progs/prog').each do |prog|

              # Model::Schedule.
              schedule = Model::Schedule.new
              schedule.module_name = self.name
              schedule.channel_name = ch_id
              schedule.title = prog.xpath('title').text
              schedule.description = prog.xpath('info').text
              schedule.from_time = time_parser(prog['ft']).to_i
              schedule.to_time = time_parser(prog['to']).to_i

              schedule.finger_print = schedule.module_name + schedule.channel_name + schedule.from_time.to_s

              schedule.save_since_finger_print_not_exist


            end

          end

        end
      end

      def time_parser(str)
        # 20130707050000 = 2013/07/07 05:00:00

        y = str[0,4]
        m = str[4,2]
        d = str[6,2]
        h = str[8,2]
        i = str[10,2]
        s = str[12,2]

        time = Time.mktime(y,m,d,h,i,s,0)
        time
      end

      def record(schedule)
        logger.debug("recroding start #{schedule.title}")

        # sleep schedule.time_to_left if schedule.time_to_left > 0 # TODO Uncomment

        tempfile = Tempfile::new('original_data')

        if realtime? && recording_delay_for_realtime > 0
          sleep recording_delay_for_realtime
        end



      end

    end

  end
end


