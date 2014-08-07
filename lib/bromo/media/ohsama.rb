module Bromo
  module Media
    class Ohsama
      include Base

      # reserved_1: bctid

      def update_db
        update_programs_from_url("http://cnt.kingrecords.co.jp/ohsama/")
      end
      def record(schedule)
        m3u_url = "http://c.brightcove.co.jp/services/mobile/streaming/index/master.m3u8?videoId=#{schedule.reserved_1}"
        recorder = Recorder::M3u.new(m3u_url, realtime?)

        data = recorder.record
        if data && data.size > 0
          file_name = generate_filename(schedule.title, schedule.video?)
          save_tempfile_and_transcode_to_data_dir(data, file_name)

          return file_name
        end

        return false
      end


      private
      def update_programs_from_url(url)
        now = Time.now.to_i
        user_agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A403 Safari/8536.25"

        begin
          # use ios user agent
          open(url,"User-Agent" => user_agent) do |f|
            base_url = 'http://cnt.kingrecords.co.jp/ohsama/sp/'

            text = f.read
            Utils.save_to_file("OHSAMA_is_valid_bctic_"+url, text)
            doc = Nokogiri::HTML(text)
            doc.css('#content4 ul li').each do |litag|

              title = litag.css(".artist_name").first.content +
                litag.css(".content_name").first.content
              desc = title

              atag = litag.css("a").first
              href = atag['href']
              description_url = "#{base_url}#{href}"


              uri = URI.parse(description_url)
              uri.query

              Bromo.debug "description_url = #{description_url}"
              Bromo.debug "query = #{uri.query}"

              bctid = nil
              uri.query.split("&").each do |q|
                if q.index('bctid=') == 0
                  bctid = q.split("=").last
                end
                break if !bctid.nil?
              end

              raise "no bctid" if bctid.nil?


              # Model::Schedule.
              schedule = Model::Schedule.new
              schedule.media_name = self.name
              schedule.channel_name = ""
              schedule.title = Utils.sanitize(title)
              schedule.description = schedule.title + ' ' + Time.now.strftime("%Y%m%d")
              schedule.from_time = 0
              schedule.to_time = 0
              schedule.finger_print = schedule.media_name + schedule.title + bctid

              schedule.reserved_1 = bctid

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



