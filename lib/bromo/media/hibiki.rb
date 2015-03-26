module Bromo
  module Media
    class Hibiki
      include Base

      # reserved_1: flv file url

      def update_db
        6.times do |num|
          update_programs_from_url("http://hibiki-radio.jp/get_program/#{num}")
        end
        true
      end

      def record(schedule)

        # data set to tempfile
        tempfile = Tempfile::new('original_data')
        Bromo.debug "#{object_id} tempfile.path = #{tempfile.path}"

        # download

        # 3times retry
        status = 0
        3.times do
          cmd = "rtmpdump \
            -s 'http://hibiki-radio.jp/player/Hibiki_FLV_Player.swf' \
            -r '#{schedule.reserved_1}' \
            -o '#{tempfile.path}' "
          Bromo.debug "#{object_id} rtmp command: #{cmd}"
          `#{cmd}`
          status = $?.to_i
          Bromo.debug "#{object_id} rtmp status: #{status}"
          break if status == 0
          sleep 3
        end

        return nil if status != 0
        Bromo.debug "#{object_id} recording done #{self.name}"

        file_name = generate_filename(schedule.title, schedule.video?)
        rec_filepath = File.join(Config.data_dir, file_name)
        file = FFMPEG::Movie.new(tempfile.path)
        file.transcode(rec_filepath)

        return file_name

      end

      def first_update?
        Model::Schedule.find_by_media_name(self.name).nil?
      end

      private
      def update_programs_from_url(url)
        now = Time.now.to_i

        begin
          open(url) do |f|
            doc = Nokogiri::HTML(f.read)

            doc.css('div.hbkProgram').each do |div|

              title = div.content
              onclick = div.css('a').first['onclick']

              if onclick.match(/^AttachVideo\('([^']+)','([^']+)'/)
                video_id = $1
                contents_id = $2
              end

              # Model::Schedule.
              schedule = Model::Schedule.new
              schedule.media_name = self.name
              schedule.channel_name = ""
              schedule.title = Utils.sanitize(title)
              schedule.description = ""
              schedule.from_time = 0
              schedule.to_time = 0
              schedule.finger_print = schedule.media_name + schedule.title

              begin
                open("http://image.hibiki-radio.jp/uploads/data/channel/#{video_id}/description.xml") do |f2|
                  doc = Nokogiri::XML(f2.read)
                  schedule.description += Utils.sanitize(doc.xpath('//data/outline').first.content)
                end
              rescue => e
                Bromo.debug e.message
                Bromo.debug "#{object_id} Can't open url F#{__FILE__} L#{__LINE__}"
                next
              end

              begin
                open("http://image.hibiki-radio.jp/uploads/data/channel/#{video_id}/#{contents_id}.xml?#{now}000") do |f3|

                  text = f3.read
                  Utils.save_to_file("hibiki_channel_#{video_id}_#{contents_id}", text)
                  doc = Nokogiri::XML(text.gsub(/&/, "&amp;"))
                  protocol = doc.xpath('//data/protocol').first.content
                  domain = doc.xpath('//data/domain').first.content
                  dir = doc.xpath('//data/dir').first.content
                  # flv = doc.xpath('//data/channel/flv').first.inner_html.gsub(/&amp;/, "&")
                  flv = doc.xpath('//data/channel/flv').first.content

                  schedule.reserved_1 = "#{protocol}://#{domain}/#{dir}/#{flv}"

                end
              rescue => e
                Bromo.debug e.message
                Bromo.debug "#{object_id} Can't open url F#{__FILE__} L#{__LINE__}"
                next
              end

              schedule.from_time = now + 60
              schedule.save_since_finger_print_not_exist

            end

          end
        rescue => e
          Bromo.debug e.message
          Bromo.debug "#{object_id} Can't open #{url} F#{__FILE__} L#{__LINE__}"
          block.call if block_given?
          return
        end

      end

    end
  end
end

