
module Bromo
  module Media
    class Toretama
      include Base

      REC_URL = "http://www.tv-tokyo.co.jp/mv/wbs/trend_tamago/"

      def update_db
        update_schedule_with_url(REC_URL)
        true
      end

      def record(schedule)
        tempfile = Tempfile::new('original_data')
        recorder = Recorder.new(REC_URL)

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
          Utils.save_to_file("TORETAMA_have_checked_updating_schedule_"+url, text)
          doc = Nokogiri::HTML(text)
          div = doc.css('div#cntL').first
          if div
            title = div.css('div.spheadboxtit').text
            description = div.css('div.article_txt').text

            # Model::Schedule.
            schedule = Model::Schedule.new
            schedule.media_name = self.name
            schedule.channel_name = ""
            schedule.title = Utils.sanitize(title)
            schedule.description = description
            schedule.from_time = 0
            schedule.to_time = 0

            # add month
            schedule.finger_print = schedule.title

            schedule.from_time = now + 60
            schedule.save_since_finger_print_not_exist

          end

        end
      end

      class Recorder < Bromo::Recorder::UlizaMobile
        def m3u_url(url)
          cookie_with(url) do |res, cookie|
            page = Nokogiri::HTML(res.body)
            script = page.css('div#cntL div.ulizaPlayer script').first
            if script
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
