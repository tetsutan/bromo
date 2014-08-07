
module Bromo
  module Media
    class Toretama
      include Base

      REC_URL = "http://www.tv-tokyo.co.jp/mv/wbs/trend_tamago/"

      def update_db
        update_schedule_with_url(REC_URL)
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
        def http_for_cookie(url)
          cookie_with(url) do |res, cookie|
            page = Nokogiri::HTML(res.body)
            script = page.css('div#cntL div.ulizaPlayer script').first
            if script
              cookie_with(script["src"], cookie) do |res2|
                replace = res2.body.gsub('\"','"')
                if replace.match(/src="([^"]+)"/)
                  self.url = $1
                end
              end
            end
          end
        end
      end

      class Recorder_ < Bromo::Recorder::Uliza
        SWF_URL = 'http://lln-img.uliza.jp/Player/784/player.swf?d=2014040920'
        FLASH_VARS_PRE = "cp=rel&log=0&mode=rel&pid=784&adgid=&eid=72230&vid=72230-287587&vidh=72230-287617&vidn=72230-287587&vidm=&sessid=0&token=9bd3f90966824e8e36dfc5de044d84d7&did=629&starttime=&chargetype=0&maxbit=&minbit=&x_query=&live=&error=&c_query=&outsidePreview=0&thisURL="
        FLASH_VARS_POST ="&lang=&langfilepath=&uuid=&element_id=ULIZA_MOVIE_PLAYER72230-287587_0de5b7a582b141d58740962185eab8b8&ei_player=&ei_timeline=&ei_uliza=&varsPrerollTimeOut=8&varsAdOnFlag=0&vastdebug=0"

        def http_for_cookie(url)

          self.play_url = url
          self.swf_url = SWF_URL
          flashvars_string = "#{FLASH_VARS_PRE}#{url}#{FLASH_VARS_POST}"

          _flashvars = {}
          flashvars_string.split("&").each do |keyval|
            key, val = keyval.split("=")
            if !_flashvars[key]
              _flashvars[key.to_sym] = val
            end
          end
          self.flashvars = _flashvars


          ## can get flashvars dynamically
          # cookie_with(url) do |res, cookie|
          #   page = Nokogiri::HTML(res.body)
          #   script = page.css('div#cntL div.ulizaPlayer script').first
          #   if script
          #     src = script['src']
          #     cookie_with(src, cookie, url) do |res2, cookie2|
          #       # serach flashvars from res2.body(javascript)
          #     end

          #   end
          # end

        end

      end

      def getDataObj(vid, flashvars)
        # https://www2.uliza.jp/api/get_player_video_info.aspx?pid=784&vid=72230%2D287587&maxbit=&minbit=&eid=72230&rnd=1256&type=1
        query = "pid=#{flashvars[:pid]}&vid=#{vid}&maxbit=&minbit=&&eid=#{flashvars[:eid]}&rnd=#{rand(10000)}&type=1"
        infourl = "https://www2.uliza.jp/api/get_player_video_info.aspx?#{query}"

        open(infourl) do |f|

          # {
          #   "TITLE": "[20140806_wb_tt01]【トレたま】氷を溶かすスプーン",
          #   "IMAGE_BEFORE_STREAM": "http://www.tv-tokyo.co.jp/mv/images/thumbnail/wbs/20140806_wb_tt01_9.jpg",
          #   "IMAGE_THUMNAIL": "http://www.tv-tokyo.co.jp/mv/images/thumbnail/wbs/20140806_wb_tt01_9.jpg",
          #   "IMAGE_BANNER": "",
          #   "FACEBOOK_TXT": "",
          #   "TWITTER_TXT": "",
          #   "LIVEDOOR_TXT": "",
          #   "DELICIOUSE_TXT": "",
          #   "GOOGLE_TXT": "",
          #   "YAHOO_TXT": "",
          #   "DESCRIPTION": "【商品名】<br />スペースマイスタースプーン<br />\r\n【商品の特徴】<br />見た目は黒いスプーンだが、素材に小惑星探査機「はやぶさ」にも使われた「カーボングラファイト」が使われている。熱拡散率が高く、触れた氷などの冷たさを奪い早く溶かす。硬いアイスクリームもすぐに食べられる。<br />\r\n【企業名】<br />ＣＳイノベーション<br />\r\n【住所】<br
          # />神奈川県横浜市中区山下町２４－８　ＳＯＨＯ　ＳＴＡＴＩＯＮ１０階<br />\r\n【価格】<br />3,060円（税込み）<br />\r\n【発売日】<br />インターネットのみで発売中<br />\r\n【トレた
          # まキャスター】<br />大澤亜季子",
          #   "NETWORK_ID": "402",
          #   "NET_CONN": "rtmp://tvtokyodm.fcod.llnwd.net/a3677/r1/",
          #   "USEBEACON_FLAG": "0",
          #   "BEACONRECEIVE_URL": "http://www2.uliza.jp/api/log/set_playlog.aspx",
          #   "BEACONPING_INTERVAL_SEC": "3",
          #   "BEACON_TYPE": "0",
          #   "LINK_URL": "",
          #   "LINK_TEXT": "",
          #   "PLAYLIST": [
          #     {
          #       "NAME": "72230-287587_20140806225248.mp4",
          #       "START": "0",
          #       "LEN": "132",
          #       "RESET": "false",
          #       "LOG_PARAMS": "di=629&pi=784&ec=72230&vc=72230-287587&si=252&gi=795&gc=2&bi=9145&bc=1&ei=769320&vi=4309843&msi=214&sl=0"
          #     }
          #   ],
          #   "SITE_ID": "252",
          #   "SITE_URL": "*",
          #   "GENRE_ID": "795",
          #   "GENRE_CODE": "2",
          #   "PROGRAM_ID": "9145",
          #   "PROGRAM_CODE": "1",
          #   "EPISODE_ID": "769320",
          #   "VIDEO_ID": "4309843",
          #   "MEMBER_SITE_ID": "214",
          #   "VIDEO_CLICK_URL": "",
          #   "CDNID": "0",
          #   "STORAGESUBDIR": "uliza_vod/video",
          #   "KEY": "",
          #   "STIME": "1407400074.09325",
          #   "USERID": "",
          #   "BANDWIDTH": "350000",
          #   "SHOW_LITTLE_FLAG": "0",
          #   "SHOW_LITTLE_START_TIME": "0",
          #   "SHOW_LITTLE_END_TIME": "0",
          #   "DYNAMIC_STREAMING": [],
          #   "LIVE_STREAMING": [],
          #   "CHAPTER": []
          # }

          json = JSON.parse(f.read)
          return getData(json, vid, flashvars)
        end

      end

    end
  end
end
