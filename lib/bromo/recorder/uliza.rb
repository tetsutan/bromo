
module Bromo
  module Recorder
    class Uliza

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

      attr_accessor :url
      def initialize(_url)
        self.url = _url
      end


      # to get variables bellow
      attr_accessor :play_url, :flashvars, :swf_url
      def http_for_cookie
        raise
      end

      def rec(file_record_to)
        http_for_cookie(url)
        if play_url.nil? || flashvars.nil? || swf_url.nil?
          Bromo.debug "#{object_id} variable not found error #{play_url} #{flashvars} #{swf_url}"
          return
        end

        vid = flashvars[:vid] || flashvars[:vidh] || flashvars[:vidn]
        p vid

        # get default
        meta = getDataObj(vid, flashvars)
        if !meta && vid != flashvars[:vidh]
          meta = getDataObj(flashvars[:vidh], flashvars)
        end
        if !meta && vid != flashvars[:vidn]
          meta = getDataObj(flashvars[:vidn], flashvars)
        end


        # create cmd
        meta[:play_list_names].each do |playlist|
          cmd = makeCommandLine(meta[:rtmp],
                                swf_url,
                                play_url,
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

            Bromo.debug "#{object_id} uliza: while 1"
            if first_time
              ret = `#{cmd} 2>&1`
              first_time = false
            else
              ret = `#{cmd} -e 2>&1` # use resume
            end

            Bromo.debug "#{object_id} uliza: ret = #{ret}"

            reverse = ret.split("\n").reverse
            complete = false
            percentage_line = ""
            5.times do |i|
              line = reverse[i].strip
              Bromo.debug "#{object_id} uliza: line = #{line}"
              if line && line.match('^Download')
                percentage_line = reverse[i+1].strip
                if !line.include?('incomplete')
                  complete = true
                end
                Bromo.debug "#{object_id} uliza: break include download"
                break
              end
            end

            Bromo.debug "#{object_id} uliza: complete = #{complete}"
            break if complete
            Bromo.debug "#{object_id} #{url} : RESUME(#{resume_count}) (#{percentage_line})"

            if percentage_line.match(/([0-9\.]+).*([0-9\.]+).*sec/)
              downloaded_byte = $1.to_f
              download_time = $2.to_f
              Bromo.debug "#{object_id} uliza: percentage_line = #{downloaded_byte}, #{download_time}"
            end
            if previous_downloaded_byte < downloaded_byte
              previous_downloaded_byte = downloaded_byte
            else
              # 数値的に進んでない、または、減った場合（おかしい場合）のみカウントを減らす
              resume_count-=1
            end

            break if resume_count < 0

            Bromo.debug "#{object_id} uliza: while last"
          end

          if resume_count < 0
            Bromo.debug "#{object_id} #{url} : Resume count over"
            return false
          else
            Bromo.debug "#{object_id} #{url} : COMPLTE!!"
            return true
          end

        end

      end

      def cookie_with(url, cookie=nil, referer=nil)

        uri = URI.parse(url)
        Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Get.new(uri.request_uri)

          FIREFOX_HEADERS.each do |k,v|
            request[k] = v
          end
          request['Host'] = uri.host
          request['Cookie'] = cookie if cookie
          request['Referer'] = referer if referer

          begin
            response = http.request(request)
          rescue Errno::ETIMEDOUT => exc
            Bromo.debug "#{object_id} ERROR: #{exc.message}"
            Bromo.debug "#{object_id} Can't open #{url} F#{__FILE__} L#{__LINE__}"
            return false
          end

          cookie = response.get_fields("Set-Cookie") if !cookie
          yield(response, cookie)
        end

      end

      def parse_cookie(original)
        cookie = {}
        original.each{|str|
          k,v = str[0...str.index(';')].split('=')
          cookie[k] = v
        }
        cookie
      end


      def makeCommandLine(rtmp, swf_url, url, playpath, content, id, out_filepath)

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
          swfVfy: swf_url,
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


      def getDataObj(vid, flashvars)
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
        title = json['TITLE'] || "uliza_#{flashvars[:id]}"
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

    class UlizaMobile < M3u
      IOS_HEADERS = {
        # "Host" => "www.animate.tv",
        "User-Agent" => "Mozilla/5.0 (iPhone; CPU iPhone OS 7_1 like Mac OS X) AppleWebKit/537.51.2 (KHTML, like Gecko) Version/7.0 Mobile/11D167 Safari/9537.53",
        "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language" => "ja,en-us;q=0.7,en;q=0.3",
        # "Accept-Encoding" => "gzip, deflate",
        # "Referer" => "http://www.animate.tv/radio/details.php?id=muromisan",
        # "Cookie" => "__utma=130647903.1882911751.1372226761.1377686703.1377690672.22; __utmz=130647903.1377118985.16.10.utmccn=(organic)|utmcsr=google|utmctr=|utmcmd=organic; pal=RPGrimoire%2CRPtsumashio%2CNP1377501378%2CRPmuromisan; atv=48701ec71f69f6155e468f325f8f0f15; __utmc=130647903; __utmb=130647903",
        "Connection" => "keep-alive",
        "Cache-Control" => "max-age=0"
        }

      attr_accessor :url_for_cookie
      def initialize(url_for_cookie, relatime = false)
        super(nil, realtime)
        self.url_for_cookie = url_for_cookie
      end

      def record(to_time=0)
        self.url = m3u_url(url_for_cookie)
        if url.nil?
          Bromo.debug "#{object_id} ERROR: m3u_url not found"
          return
        end
        super(to_time)
      end

      def cookie_with(url, cookie=nil, referer=nil)

        uri = URI.parse(url)
        Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Get.new(uri.request_uri)

          IOS_HEADERS.each do |k,v|
            request[k] = v
          end
          request['Host'] = uri.host
          request['Cookie'] = cookie if cookie
          request['Referer'] = referer if referer

          begin
            response = http.request(request)
          rescue Errno::ETIMEDOUT => exc
            Bromo.debug "#{object_id} ERROR: #{exc.message}"
            Bromo.debug "#{object_id} Can't open #{url} F#{__FILE__} L#{__LINE__}"
            return false
          end

          cookie = response.get_fields("Set-Cookie") if !cookie
          yield(response, cookie)
        end

      end


    end

  end
end



