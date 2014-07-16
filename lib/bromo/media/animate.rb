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
        recorder = AnimateRecorder.new

        Bromo.debug "#{object_id} animate record to #{tempfile.path}"
        if !recorder.rec(schedule.reserved_1, tempfile)
          return false
        end

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


      class AnimateRecorder

        BASE_URL = 'http://www.animate.tv'
        CHROME_USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.912.75 Safari/535.7'

        FIREFOX_HEADERS = {
          "Host" => "www.animate.tv",
          "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:23.0) Gecko/20100101 Firefox/23.0",
          "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
          "Accept-Language" => "ja,en-us;q=0.7,en;q=0.3",
          # "Accept-Encoding" => "gzip, deflate",
          # "Referer" => "http://www.animate.tv/radio/details.php?id=muromisan",
          # "Cookie" => "__utma=130647903.1882911751.1372226761.1377686703.1377690672.22; __utmz=130647903.1377118985.16.10.utmccn=(organic)|utmcsr=google|utmctr=|utmcmd=organic; pal=RPGrimoire%2CRPtsumashio%2CNP1377501378%2CRPmuromisan; atv=48701ec71f69f6155e468f325f8f0f15; __utmc=130647903; __utmb=130647903",
          "Connection" => "keep-alive",
          "Cache-Control" => "max-age=0"
          }



        def rec(file_url, file_record_to)

          detail_uri = URI.parse(file_url)
          Net::HTTP.start(detail_uri.host, detail_uri.port) do |http|
            request = Net::HTTP::Get.new(detail_uri.request_uri)
            begin
              response = http.request(request)
            rescue Errno::ETIMEDOUT => exc
              Bromo.debug "#{object_id} ERROR: #{exc.message}"
              Bromo.debug "#{object_id} Can't open #{file_url} F#{__FILE__} L#{__LINE__}"
              return false
            end

            cookie = {}
            cookie_original = response.get_fields("Set-Cookie")
            cookie_original.each{|str|
              k,v = str[0...str.index(';')].split('=')
              cookie[k] = v
            }

            # before get cookie
            if cookie["atv"]

              detail_page = Nokogiri::HTML(response.body)
              detail_page.css('div.playBox').each do |playbox|
                title = playbox.css('div.ttlArea h3').first.content
                playpath = playbox.css('div.btnArea p.btn a').first['href']

                next if title.include?("WMP") # ignore wmv

                play_uri = URI.parse("#{BASE_URL}#{playpath}")
                Net::HTTP.start(play_uri.host, play_uri.port) do |http|
                  request = Net::HTTP::Get.new(play_uri.request_uri)

                  FIREFOX_HEADERS.each do |k,v|
                    request[k] = v
                  end
                  request['Cookie'] = cookie_original
                  request['Referer'] = file_url


                  begin
                    response = http.request(request)
                  rescue Errno::ETIMEDOUT => exc
                    Bromo.debug "#{object_id} ERROR: #{exc.message}"
                    Bromo.debug "#{object_id} Can't open #{playpath} F#{__FILE__} L#{__LINE__}"
                    next
                  end

                  doc = Nokogiri::HTML(response.body)

                  # get flashvars
                  flashvars = {}
                  response.body.gsub(/"FlashVars"\s*,([^,]+),/) do |flashvars_match|

                    %w/pid did eid vid token vidh vidn/.map(&:to_sym).each do |key|
                      if !flashvars[key] && flashvars_match.match(/&#{key}=([^&]+)/)
                        flashvars[key] = $1
                      end
                    end
                  end

                  # get swfurl
                  object_movie = doc.css('object param[name="movie"]')
                  if object_movie.first
                    swfurl = object_movie.first['value']
                  end

                  vid = flashvars[:vid] || flashvars[:vidh] || flashvars[:vidn]

                  # get default
                  meta = getDataObj(vid, flashvars, response)
                  if !meta && vid != flashvars[:vidh]
                    meta = getDataObj(flashvars[:vidh], flashvars, response)
                  end
                  if !meta && vid != flashvars[:vidn]
                    meta = getDataObj(flashvars[:vidn], flashvars, response)
                  end


                  # create cmd
                  meta[:play_list_names].each do |playlist|
                    cmd = makeCommandLine(meta[:rtmp],
                                          swfurl,
                                          play_uri.to_s,
                                          playlist,
                                          meta[:content],
                                          flashvars[:id],
                                          file_record_to
                                         )
                    Bromo.debug "#{object_id} RTMP command = #{cmd}"

                    first_time = true
                    resume_count = 20
                    previous_downloaded_byte = 0

                    while true

                      Bromo.debug "#{object_id} animate: while 1"
                      if first_time
                        ret = `#{cmd} 2>&1`
                        first_time = false
                      else
                        ret = `#{cmd} -e 2>&1` # use resume
                      end

                      Bromo.debug "#{object_id} animate: ret = #{ret}"

                      reverse = ret.split("\n").reverse
                      complete = false
                      percentage_line = ""
                      5.times do |i|
                        line = reverse[i].strip
                        Bromo.debug "#{object_id} animate: line = #{line}"
                        if line && line.match('^Download')
                          percentage_line = reverse[i+1].strip
                          if !line.include?('incomplete')
                            complete = true
                          end
                          Bromo.debug "#{object_id} animate: break include download"
                          break
                        end
                      end

                      Bromo.debug "#{object_id} animate: complete = #{complete}"
                      break if complete
                      Bromo.debug "#{object_id} #{file_url} : RESUME(#{resume_count}) (#{percentage_line})"

                      if percentage_line.match(/([0-9\.]+).*([0-9\.]+).*sec/)
                        downloaded_byte = $1.to_f
                        download_time = $2.to_f
                        Bromo.debug "#{object_id} animate: percentage_line = #{downloaded_byte}, #{download_time}"
                      end
                      if previous_downloaded_byte < downloaded_byte
                        previous_downloaded_byte = downloaded_byte
                      else
                        # 数値的に進んでない、または、減った場合（おかしい場合）のみカウントを減らす
                        resume_count-=1
                      end

                      break if resume_count < 0

                      Bromo.debug "#{object_id} animate: while last"
                    end

                    if resume_count < 0
                      Bromo.debug "#{object_id} #{file_url} : Resume count over"
                      return false
                    else
                      Bromo.debug "#{object_id} #{file_url} : COMPLTE!!"
                      return true
                    end

                  end


                end

              end

            end


          end

        end

        def makeCommandLine(rtmp, swfurl, url, playpath, content, id, out_filepath)

          uri = URI.parse(rtmp)
          protocol = uri.scheme
          port = uri.port
          domain = uri.host
          domain = "#{domain}:#{port}" if port
          app = uri.path
          app = app[1..app.size] if app[0] == "/"

          # recreate playpath
          if playpath
            arr1 = playpath.split("/")
            file = arr1.pop
            arr2 = file.split(".")
            if arr2.size > 1
              extention = arr2.pop
              if extention == "mp4"
                arr2[0] = "mp4:#{arr2[0]}"
                arr2.push("mp4")
              end
            end
            arr1.push(arr2.join("."))
            playpath = arr1.join("/")
          end

          # flashver = "11.8.800.94"
          flashver = "WIN 10,0,32,18"
          flashver = nil

          values = {
            rtmp: rtmp,
            app: app,
            swfVfy: swfurl,
            flashVer: flashver,
            pageUrl: url,
            playpath: playpath,
          }

          _v = []
          values.each do |k,v|
            _v.push("--#{k} \"#{v}\"") if v
          end

          return [
            "rtmpdump",
            _v.join(" "),
            content,
            "-o #{out_filepath.path}"
          ].join(" ")

        end


        def getDataObj(vid, flashvars, objHttp)
          query = "vid=#{vid}&eid=#{flashvars[:eid]}&pid=#{flashvars[:pid]}&rnd=#{rand(10000)}"
          infourl = "https://www2.uliza.jp/api/get_player_video_info.aspx?#{query}"

          open(infourl) do |f|
            json = JSON.parse(f.read)
            return getData(json, vid, flashvars)
          end

        end

        def getData(json, vid, flashvars)
          net_conn = json['NET_CONN'] || ""
          play_list = json['PLAYLIST'] || []
          play_list_names = play_list.map{|o| o['NAME'] }
          title = json['TITLE'] || "animate_#{flashvars[:id]}"
          title.gsub!(/[\\\/:*?"<>|]/,"_")
          cdnid = json['CDNID'].to_i

          return nil if play_list_names.empty?

          case cdnid
          when 1
            key = json['KEY'] || ""
            userid = json['USERID'] || ""
            rtmp = "#{net_conn}?key=#{key}"
            content = "-C S:#{userid}"
          when 2,3,5
            rtmp = net_conn
            content = ""
          when 4
            key = json['KEY'] || ""
            return nil if !key
            stime = json['STIME'] ? json['STIME'].to_i : Time.now.to_i
            stime -= 1
            etime = stime + 5 * 3600
            data = "#{flashvars[:did]}#{flashvars[:pid]}#{flashvars[:eid]}#{key}#{vid}#{stime}#{etime}"
            hexhash = Digest::MD5.hexdigest(data)

            rtmp = net_conn
            content = [ 
                  "-C O:1",
                  "-C NS:stm:#{stime}",
                  "-C NS:pid:#{flashvars[:pid]}",
                  "-C NS:hash:#{hexhash}",
                  "-C NS:etm:#{etime}",
                  "-C NS:eid:#{flashvars[:eid]}",
                  "-C NS:did:#{flashvars[:did]}",
                  "-C NS:vid:#{vid}",
                  "-C O:0"
            ].join(" ")

          else
            rtmp = net_conn
            content = "-C S:#{flashvars[:token]}"
          end


          return {
            play_list_names: play_list_names,
            rtmp: rtmp,
            content: content,
            title: title,
            vid: vid
          }

        end


      end

    end
  end
end

