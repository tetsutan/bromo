module Bromo
  module Media
    class Onsen
      include Base

      # onsen use reserved_1 for downloadable mp3 url

      def update_db
        now = Time.now.to_i

        (1..5).each do |week_num|
          update_programs_from_url("http://www.onsen.ag/getXML.php?#{now*1000}",{'file_name' => "regular_#{week_num}"})
        end

      end
      def record(schedule)
        recorder = Recorder::Url.new(schedule)
        file_name = generate_filename(schedule.title, schedule.video?)
        return recorder.record(schedule.reserved_1, file_name)
      end


      def update_programs_from_url(url,params)

        now = Time.now.to_i

        uri = URI::parse(url)
        Net::HTTP.start(uri.host, uri.port) do |http|
          req = Net::HTTP::Post.new(uri.path)
          req.set_form_data(params, '&')
          begin
            res = http.request(req)
          rescue Errno::ETIMEDOUT => exc
            Bromo.debug "#{object_id} ERROR: #{exc.message}"
            Bromo.debug "#{object_id} Can't open #{url} F#{__FILE__} L#{__LINE__}"
            return
          end

          doc = Nokogiri::XML(res.body)

          doc.xpath('//data/regular/program').each do |prog|

            # cmのmp3が含まれていることがあるので、そのURLを含むデータは
            # 除いて、最後のmp3をfile_urlとする
            file_url = prog.xpath('contents/fileUrl').select do |url|
              !url.text.include?('http://onsen.b-ch.com/cm/')
            end.last

            next if file_url.nil?
            file_url = file_url.text


            # Model::Schedule.
            schedule = Model::Schedule.new
            schedule.media_name = self.name
            schedule.channel_name = ""
            schedule.title = Utils.sanitize(prog.xpath('title').text)
            schedule.description = Utils.sanitize(prog.xpath('update').text) + ' ' +
              Utils.sanitize(prog.xpath('number').text) + ' ' +
              Utils.sanitize(prog.xpath('text').text) + ' ' +
              Utils.sanitize(prog.xpath('detailURL').text)

            schedule.from_time = 0
            schedule.to_time = 0

            schedule.reserved_1 = file_url

            schedule.finger_print = schedule.media_name + schedule.description

            if Model::Schedule.where(finger_print: schedule.finger_print).empty?
              schedule.from_time = now + 60
              schedule.save_since_finger_print_not_exist
            end

            # image_path = prog.xpath('imagePath').text
            # program.image_url = "http://www.onsen.ag/#{image_path}" if image_path

            # if Model::Schedule.where(finger_print: schedule.finger_print).empty?
            #   # 予約済みでなければ from_timeを 60sec後に設定
            #   schedule.from_time = now + 60
            #   schedule.save_since_finger_print_not_exist
            # end

          end

        end


      end

    end
  end
end


