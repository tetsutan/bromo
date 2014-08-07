module Bromo
  module Media
    class Animate
      include Base

      # reserved_1: detail path
      # reserved_2: page update_date (Time.at(XX).to_i.to_s)

      def update_db
        last_update_schedule = Model::Schedule.order("reserved_2 DESC").limit(1)

        last_update = Time.at(0)
        if !last_update_schedule.empty?
          last_update = Time.at(last_update_schedule.first.reserved_2.to_i)
        end

        offset = 0
        while update_programs_from_url_with_lastupdate("http://www.animate.tv/posts_list.php?name=%2Fradio%2F&offset=#{offset}&tagid=&category=radio", last_update)

          Bromo.exsleep 10 # avoid 503

          offset += 10
          Bromo.debug "#{object_id} animate page offset = #{offset}"

          break if !Bromo::Core.running?
          break if offset > 50 # force break
        end
      end

      def record(schedule)
        tempfile = Tempfile::new('original_data')
        recorder = Recorder.new(schedule.reserved_1)

        Bromo.debug "#{object_id} animate record to #{tempfile.path}"
        if !recorder.rec(tempfile)
          return false
        end

        delay_converting
        file_name = generate_filename(schedule.title, schedule.video?)
        rec_filepath = File.join(Config.data_dir, file_name)
        file = FFMPEG::Movie.new(tempfile.path)
        file.transcode(rec_filepath)

        return file_name

      end

      def update_programs_from_url_with_lastupdate(url, last_update)
        now = Time.now.to_i

        Bromo.debug "#{object_id} open #{url}"
        begin
          open(url) do |f|
            Bromo.debug "#{object_id} got #{url}"
            doc = Nokogiri::HTML(f.read)

            doc.css('div.contents_block_A').each do |div|

              base_url = 'http://www.animate.tv'

              title_tag = div.css('p.title').first
              if title_tag
                title = title_tag.content
                detail_path = title_tag.css('a').first['href']
              end
              date_string = div.css('p.date').first.child.content
              update_date = 0

              begin
                update_date = Time.parse(date_string) if  date_string
                return false if update_date.to_i < last_update.to_i
              end

              open("#{base_url}#{detail_path}") do |f2|
                detail_page = Nokogiri::HTML(f2.read)

                description = detail_page.css('div.textBox').first.text

                detail_page.css('div.playBox').each do |playbox|
                  title = playbox.css('div.ttlArea h3').first.content
                  playpath = playbox.css('div.btnArea p.btn a').first['href']
                  _date = playbox.css('div.ttlArea span.date').first.content

                  next if title.include?("WMP") # ignore wmv

                  # Model::Schedule.
                  schedule = Model::Schedule.new
                  schedule.media_name = self.name
                  schedule.channel_name = ""
                  schedule.title = Utils.sanitize(title)
                  schedule.description = description
                  schedule.from_time = 0
                  schedule.to_time = 0

                  # rescan detail_path to get cookie
                  schedule.reserved_1 = "#{base_url}#{detail_path}" if playpath

                  schedule.finger_print = title + " " + _date

                  schedule.reserved_2 = update_date.to_i.to_s

                  schedule.from_time = now + 60
                  schedule.save_since_finger_print_not_exist

                end

              end
            end

          end
        rescue => e
          Bromo.debug e.message
          Bromo.debug "#{object_id} Can't open #{url} F#{__FILE__} L#{__LINE__}"
          return true
        end

        return true
      end

      class Recorder < Bromo::Recorder::Uliza

        BASE_URL = 'http://www.animate.tv'

        def http_for_cookie(url)
          cookie_with(url) do |res, cookie|
            # before get cookie
            cookie_hash = parse_cookie(cookie)
            if cookie_hash["atv"]
              detail_page = Nokogiri::HTML(res.body)
              detail_page.css('div.playBox').each do |playbox|
                title = playbox.css('div.ttlArea h3').first.content
                playpath = playbox.css('div.btnArea p.btn a').first['href']

                next if title.include?("WMP") # ignore wmv

                self.play_url = "#{BASE_URL}#{playpath}"
                cookie_with(self.play_url, cookie, url) do |res2|

                  doc = Nokogiri::HTML(res2.body)

                  # get flashvars
                  _flashvars = {}
                  res2.body.gsub(/"FlashVars"\s*,([^,]+),/) do |flashvars_match|

                    %w/pid did eid vid token vidh vidn/.map(&:to_sym).each do |key|
                      if !_flashvars[key] && flashvars_match.match(/&#{key}=([^&]+)/)
                        _flashvars[key] = $1
                      end
                    end
                  end
                  self.flashvars = _flashvars

                  # get swf_url
                  object_movie = doc.css('object param[name="movie"]')
                  if object_movie.first
                    self.swf_url = object_movie.first['value']
                  end

                end


              end
            end

          end
        end

      end


    end
  end
end

