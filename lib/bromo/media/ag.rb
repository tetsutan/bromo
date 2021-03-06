module Bromo
  module Media
    class Ag
      include Base

      realtime :true
      recording_delay_for_realtime 120
      recording_extra_for_realtime 30
      refresh_time "0 5 * * *"

      def update_db
        update_programs_from_url("http://ic-www.uniqueradio.jp/iphone_pg/get_program_json3.php")
        true
      end
      def record(schedule)
        recorder = Recorder::M3u.new("http://ic-www.uniqueradio.jp/iphone/3G.m3u8", realtime?)
        sleep_recording_delay(schedule)
        data = recorder.record(schedule.to_time + recording_extra_for_realtime)
        if data && data.size > 0
          file_name = generate_filename(schedule.title, schedule.video?)
          save_tempfile_and_transcode_to_data_dir(data, file_name)

          return file_name
        end

        return false
      end

      def update_programs_from_url(url)

        begin
          open(url) do |f|

            now = Time.now

            program_list = JSON.load(f.read)

            # {
            #   "start" : "25:00",
            #   "end" : "25:30",
            #   "title" : "金田朋子・保村真のエアラジオ",
            #   "personality" : "<img src=\"http://ic-www.uniqueradio.jp/img/p.gif\">金田朋子・保村真",
            #   "detail" : ""
            # },


            programs = program_list['program']
            if programs
              programs.each do |prog|

                next if prog['title'].include?('放送休止')

                # jsonにタグが入っているので取り除く
                prog['title'] = Utils.sanitize(prog['title'])
                prog['personality'] = Utils.sanitize(prog['personality'])
                prog['detail'] = Utils.sanitize(prog['detail'])

                # Model::Schedule.
                schedule = Model::Schedule.new
                schedule.media_name = self.name
                schedule.channel_name = ""
                # schedule.title = prog['title']
                schedule.description = prog['personality'] + prog['detail']

                # スケジュールリストが午前４時に更新されるので、
                # 午前4時以前に取得した場合は昨日のスケジュールとして管理するが
                # 境界値でエラーを出さないために更新タイミングは５時に設定しておいたほうがいい
                from_to = ::Bromo::Utils::Date.today(
                  prog['start'].sub(":",""),
                  prog['end'].sub(":","")
                )
                schedule.from_time = from_to[0].to_i
                schedule.to_time = from_to[1].to_i

                if(now < Bromo::Utils::Date.today("500", "500")[0])
                  # 昨日のデータ
                  schedule.from_time += 24*60*60
                  schedule.to_time += 24*60*60
                end

                schedule.title = prog['title'] + " " +
                  Time.at(schedule.from_time).strftime("%m/%d")

                schedule.finger_print = schedule.media_name + schedule.from_time.to_s

                schedule.save_since_finger_print_not_exist

              end
            end

          end
        rescue => e
          Bromo.debug e.message
          Bromo.debug "#{object_id} Can't open #{url} F#{__FILE__} L#{__LINE__}"
        end
      end


    end
  end
end

