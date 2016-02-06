module Bromo
  module Media
    class LogirlArchive
      include Base

      # reserved_1: detail id

      URL = "https://ex-chaos.appspot.com/_ah/api/article/v2/article?corePortalID=logirl&cursor=&limit=9&orderBy=publishAt&tag=%E7%95%AA%E7%B5%84%E3%82%A2%E3%83%BC%E3%82%AB%E3%82%A4%E3%83%96%E5%8B%95%E7%94%BB&visibility=site"
      def update_db

        # 1日１回チェックしてたら大丈夫っぽいのでとりあえず最初の９件だけ
        # 本当はanimate式
        update_schedule_with_url(URL)
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
        begin
          open(url) do |f|
            text = f.read
            Utils.save_to_file("LogirlArchive_update_"+url, text)
            program_list = JSON.load(text)
            list = program_list['list']
            list.each do |prog|

              # {
              #   "id": "5686297985286144",
              #   "corePortalID": "logirl",
              #   "displayTypes": [
              #     "plain"
              #   ],
              #   "headerType": "thumbnail",
              #   "title": "【動画】お正月ムードでお年玉交換会！「イヤホンズの戦略かいぎしつβ」♯3",
              #   "body": "[uliza:clientid=1249&episodeid=201602012102108]\n\n「イヤホンズの戦略かいぎしつβ」♯3（2016年1月21日配信分）\n\n### 出演者\nイヤホンズ（高橋李依、高野麻里佳、長久友紀）",
              #   "plainText": "「イヤホンズの戦略かいぎしつβ」♯3（2016年1月21日配信分） 出演者 イヤホンズ（高橋李依、高野麻里佳、長久友紀）",
              #   "status": "publish",
              #   "thumbnailURL": "//ex-chaos.appspot.com/api/download/e3c94bc5-53e2-4123-a1d5-64ae0212236d_large",
              #   "tags": [
              #     {
              #       "corePortalID": "logirl",
              #       "text": "番組アーカイブ動画",
              #       "icon": "fa-video-camera",
              #       "articleCount": 339,
              #       "createdAt": "2016-02-02T20:06:36.776902Z",
              #       "updatedAt": "2016-02-04T07:32:57.442633Z"
              #     },
              #     {
              #       "corePortalID": "logirl",
              #       "text": "動画",
              #       "icon": "fa-film",
              #       "articleCount": 1022,
              #       "createdAt": "2016-02-02T20:06:18.956852Z",
              #       "updatedAt": "2016-02-04T07:32:57.44112Z"
              #     },
              #     {
              #       "corePortalID": "logirl",
              #       "text": "イヤホンズ",
              #       "icon": "fa-male",
              #       "articleCount": 9,
              #       "createdAt": "2016-02-02T20:06:01.774508Z",
              #       "updatedAt": "2016-02-04T07:32:57.441694Z"
              #     },
              #     {
              #       "corePortalID": "logirl",
              #       "text": "「イヤホンズの戦略かいぎしつβ」",
              #       "icon": "fa-asterisk",
              #       "articleCount": 4,
              #       "createdAt": "2016-02-02T20:05:46.110039Z",
              #       "updatedAt": "2016-02-04T07:32:57.443232Z"
              #     }
              #   ],
              #   "defaultType": "article",
              #   "publishAt": "2016-02-04T07:00:00Z",
              #   "autoPublishAt": "0001-01-01T00:00:00Z",
              #   "autoUnpublishAt": "0001-01-01T00:00:00Z",
              #   "createdAt": "0001-01-01T00:00:00Z",
              #   "updatedAt": "0001-01-01T00:00:00Z",
              #   "purchaseStatus": "notRequired"
              # }



                schedule = Model::Schedule.new
                schedule.media_name = self.name
                schedule.channel_name = ""
                schedule.title = Utils.sanitize(prog['title'])
                schedule.description = Utils.sanitize(prog['body'])

                schedule.from_time = now + 60
                schedule.to_time = 0

                schedule.reserved_1 = prog['id']
                schedule.finger_print = schedule.reserved_1

                schedule.save_since_finger_print_not_exist

            end

          end

        rescue => e
          Bromo.debug e.message
          puts e.backtrace
          Bromo.debug "#{object_id} Can't open #{url} F#{__FILE__} L#{__LINE__}"
          block.call if block_given?
          return
        end

      end

      class Recorder < Bromo::Recorder::UlizaMobile

        def m3u_url(id)

          url = "https://ex-chaos.appspot.com/_ah/api/article/v2/article/#{id}?corePortalID=logirl&tag=%E7%95%AA%E7%B5%84%E3%82%A2%E3%83%BC%E3%82%AB%E3%82%A4%E3%83%96%E5%8B%95%E7%94%BB&visibility=site"

          open(url, IOS_HEADERS) do |f|

            # {
            #  "id": "5686297985286144",
            #  "corePortalID": "logirl",
            #  "displayTypes": [
            #   "plain"
            #  ],
            #  "headerType": "thumbnail",
            #  "title": "【動画】お正月ムードでお年玉交換会！「イヤホンズの戦略かいぎしつβ」♯3",
            #  "body": "[uliza:clientid=1249&episodeid=201602012102108]\n\n「イヤホンズの戦略かいぎしつβ」♯3（2016年1月21日配信分）\n\n### 出演者\nイヤホンズ（高橋李依、高野麻里佳、長久友紀）",
            #  "plainText": "「イヤホンズの戦略かいぎしつβ」♯3（2016年1月21日配信分） 出演者 イヤホンズ（高橋李依、高野麻里佳、長久友紀）",
            #  "status": "publish",
            #  "thumbnailURL": "//ex-chaos.appspot.com/api/download/e3c94bc5-53e2-4123-a1d5-64ae0212236d_large",
            #  "tags": [
            #   {
            #    "corePortalID": "logirl",
            #    "text": "番組アーカイブ動画",
            #    "icon": "fa-video-camera",
            #    "articleCount": 339,
            #    "createdAt": "2016-02-02T20:06:36.776902Z",
            #    "updatedAt": "2016-02-04T07:32:57.442633Z"
            #   },
            #   {
            #    "corePortalID": "logirl",
            #    "text": "動画",
            #    "icon": "fa-film",
            #    "articleCount": 1022,
            #    "createdAt": "2016-02-02T20:06:18.956852Z",
            #    "updatedAt": "2016-02-04T07:32:57.44112Z"
            #   },
            #   {
            #    "corePortalID": "logirl",
            #    "text": "イヤホンズ",
            #    "icon": "fa-male",
            #    "articleCount": 9,
            #    "createdAt": "2016-02-02T20:06:01.774508Z",
            #    "updatedAt": "2016-02-04T07:32:57.441694Z"
            #   },
            #   {
            #    "corePortalID": "logirl",
            #    "text": "「イヤホンズの戦略かいぎしつβ」",
            #    "icon": "fa-asterisk",
            #    "articleCount": 4,
            #    "createdAt": "2016-02-02T20:05:46.110039Z",
            #    "updatedAt": "2016-02-04T07:32:57.443232Z"
            #   }
            #  ],
            #  "defaultType": "article",
            #  "publishAt": "2016-02-04T07:00:00Z",
            #  "autoPublishAt": "0001-01-01T00:00:00Z",
            #  "autoUnpublishAt": "0001-01-01T00:00:00Z",
            #  "createdAt": "0001-01-01T00:00:00Z",
            #  "updatedAt": "0001-01-01T00:00:00Z",
            #  "prevID": "5677103265611776",
            #  "nextID": "5745201784029184",
            #  "purchaseStatus": "notRequired",
            #  "kind": "article#resourcesItem",
            #  "etag": "\"Ai4TsuHu1e1q67T2gY_4c57uuQA/rj-2U5oZUxmG3BzK01PETiDsKOM\""
            # }

            text = f.read
            Utils.save_to_file("LogirlArchive_rec_"+url, text)
            detail = JSON.load(text)

            detail["body"].match(/^\[([^\]]+)\]/) do |match|

              episode_key = match[1]
              Bromo.debug "#{object_id} episode_key: #{episode_key}"

              if episode_key
                type, param = episode_key.split(":", 2)

                # current uliza only
                if type == "uliza" && param

                  _now = (Time.now.to_f * 1000).to_i.to_s # 1454714408276
                  uliza_url = "https://www2.uliza.jp/IF/RequestVideoTag.aspx?#{param}&" +
                    "playertype=OSMFPlayer&u_option_autoplay=1&u_base_pw=640&u_base_ph=360&u_base_androidpw=640&u_base_androidph=360&" +
                    "targetid=player#{_now}&" +
                    "showbuttons=%2F1%2F4%2F5%2F6%2F7%2F"

                  header = IOS_HEADERS
                  referer = "https//logirl.favclip.com/article/detail/#{id}?tag=%E7%95%AA%E7%B5%84%E3%82%A2%E3%83%BC%E3%82%AB%E3%82%A4%E3%83%96%E5%8B%95%E7%94%BB" # Detail page url
                  header["Referer"] = referer
                  Utils.cookie_with(uliza_url, header) do |res2, cookie|
                    header["Cookie"] = cookie
                    self.request_options = header

                    data = res2.body
                    replace = data.gsub('\"','"')
                    # replace = f2.read.gsub('\"','"')
                    if replace.match(/src="([^"]+)"/)
                      return $1
                    end
                  end


                end # end uliza

              end
            end

          end
          nil
        end
      end

    end
  end
end

