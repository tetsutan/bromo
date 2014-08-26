
module Bromo
  module Media
    class PiramekiMaaya
      include Base

      # reserved_1: detail path

      # REC_URL = "http://www.tv-tokyo.co.jp/pirameki/gallery/maya/"
      REC_URL_BASE = "http://www.tv-tokyo.co.jp/pirameki/gallery/maya/"
      REC_URL = "#{REC_URL_BASE}/list_movie.js"

      def update_db
        update_schedule_with_url(REC_URL)
      end

      def record(schedule)
        tempfile = Tempfile::new('original_data')
        recorder = Recorder.new(schedule.reserved_1)

        data = recorder.record
        if data && data.size > 0
          file_name = generate_filename(schedule.title, schedule.video?)
          save_tempfile_and_transcode_to_data_dir(data, file_name)

          return file_name
        end

        return false
      end

      def update_schedule_with_url(url)
        now = Time.now.to_i

        open(url) do |f|
          text = f.read
          Utils.save_to_file("PiramekiMaaya_have_checked_updating_schedule_"+url, text)

          text.split("m_moviebox2").each do |divv|
            # p divv
            if divv =~ /<a href="([^"]+?)".*<p class.*?>(.+?)<\/p/m
              url = $1
              title = $2

              # Model::Schedule.
              schedule = Model::Schedule.new
              schedule.media_name = self.name
              schedule.channel_name = ""
              schedule.title = Utils.sanitize(title)
              schedule.description = ""
              schedule.from_time = 0
              schedule.to_time = 0

              schedule.reserved_1 = REC_URL_BASE + url

              # add month
              schedule.finger_print = schedule.title

              schedule.from_time = now + 60
              schedule.save_since_finger_print_not_exist


            end

          end

        end
      end

      class Recorder < Bromo::Recorder::UlizaMobile

        def m3u_url(url)
          cookie_with(url) do |res, cookie|
            page = Nokogiri::HTML(res.body)
            page.css('div#leftMain table script').each do |script|
              next unless URI.parse(script['src']).host =~ /uliza\.jp$/
              cookie_with(script["src"], cookie) do |res2|
                replace = res2.body.gsub('\"','"')
                if replace.match(/src="([^"]+)"/)
                  return $1
                end
              end
            end
          end
          nil
        end

      end


    end
  end
end
