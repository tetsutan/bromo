module Bromo
  module Media
    class Hibiki
      include Base

      # reserved_1: page access_id

      def update_db
        update_programs_from_url("https://vcms-api.hibiki-radio.jp/api/v1//programs")
        true
      end

      def record(schedule)

        access_id = schedule.reserved_1
        Utils.cookie_with("https://vcms-api.hibiki-radio.jp/api/v1/programs/#{access_id}",
             "User-Agent" => user_agent,
             "X-Requested-With" => "XMLHttpRequest",
             "Referer" => "http://hibiki-radio.jp/description/#{access_id}/detail"
            ) do |res, cookie|

          program = JSON.load(res.body)
          video_id = program["episode"]["video"]["id"]

          if video_id
            Utils.cookie_with("https://vcms-api.hibiki-radio.jp/api/v1/videos/play_check?video_id=#{video_id}",
                 "User-Agent" => user_agent,
                 "X-Requested-With" => "XMLHttpRequest",
                 "Referer" => "http://hibiki-radio.jp/description/#{access_id}/detail",
                 "Cookie" => cookie
                ) do |res2, cookie2|
              video = JSON.load(res2.body)
              playlist_url = video["playlist_url"]
              if playlist_url
                recorder = Recorder::M3u.new(playlist_url, realtime?, {
                  "User-Agent" => user_agent,
                  "Referer" => "http://hibiki-radio.jp/",
                  "Cookie" => cookie2
                })

                data = recorder.record
                if data && data.size > 0
                  file_name = generate_filename(schedule.title, schedule.video?)
                  save_tempfile_and_transcode_to_data_dir(data, file_name)

                  return file_name
                end

              end
            end
          end

        end


        return false
      end

      def first_update?
        Model::Schedule.find_by_media_name(self.name).nil?
      end

      def user_agent
        "Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A403 Safari/8536.25"
      end

      private
      def update_programs_from_url(url)
        now = Time.now.to_i
        begin
          # use ios user agent
          open(url,
               "User-Agent" => user_agent,
               "X-Requested-With" => "XMLHttpRequest",
               "Referer" => "http://hibiki-radio.jp/"
              ) do |f|

            text = f.read
            Utils.save_to_file("hibiki_update_"+url, text)
            program_list = JSON.load(text)

            # [
            #     {
            #         "access_id": "shisyunki41",
            #         "cast": "",
            #         "copyright": "©HiBiKi Radio Station",
            #         "day_of_week": 6,
            #         "description": "浅沼晋太郎・鷲崎健の「思春期が終わりません」第41回アーカイブです！",
            #         "email": null,
            #         "episode": {
            #             "additional_video": null,
            #             "chapters": null,
            #             "episode_parts": null,
            #             "html_description": "",
            #             "id": 442,
            #             "link_url": "",
            #             "media_type": null,
            #             "name": "第41回",
            #             "updated_at": "2015/12/27 13:31:50",
            #             "video": null
            #         },
            #         "episode_updated_at": "2015/12/30 12:00:00",
            #         "hash_tag": "",
            #         "id": 62,
            #         "latest_episode_id": 442,
            #         "latest_episode_name": "第41回",
            #         "message_form_url": null,
            #         "meta_description": "",
            #         "meta_keyword": "",
            #         "meta_title": "",
            #         "name": "浅沼晋太郎・鷲崎健の思春期が終わりません　第41回",
            #         "name_kana": "",
            #         "new_program_flg": false,
            #         "onair_information": "2015年12月30日～2016年3月9日配信です！",
            #         "pc_image_info": {
            #             "height": 400,
            #             "width": 1000
            #         },
            #         "pc_image_url": "http://hibikiradiovms.blob.core.windows.net/image/uploads/program_banner/image1/63/ba649f4c-5b29-483d-9ecd-58105428fdae.jpg",
            #         "priority": 98,
            #         "publish_end_at": "2016/03/09 12:00:00",
            #         "publish_start_at": "2015/12/30 12:00:00",
            #         "share_text": "響ラジオステーションで「浅沼晋太郎・鷲崎健の思春期が終わりません　第41回」を楽しもう!",
            #         "share_url": "http://bit.ly/1mH7BDa",
            #         "sp_image_info": {
            #             "height": 360,
            #             "width": 640
            #         },
            #         "sp_image_url": "http://hibikiradiovms.blob.core.windows.net/image/uploads/program_banner/image2/63/0c5c547d-188f-4357-b7a8-53df96df04e1.jpg",
            #         "update_flg": false,
            #         "updated_at": "2015/12/27 13:30:57"
            #     }
            # ]

            if program_list.is_a? Array
              program_list.each do |prog|
                schedule = Model::Schedule.new
                schedule.media_name = self.name
                schedule.channel_name = ""
                schedule.title = Utils.sanitize(prog['name'])
                episode_name = Utils.sanitize(prog['latest_episode_name'])
                if !schedule.title.include?(episode_name)
                  schedule.title += " " +  episode_name
                end
                schedule.description = Utils.sanitize(prog['description'])
                schedule.from_time = 0
                schedule.to_time = 0

                schedule.reserved_1 = prog['access_id']

                schedule.finger_print = schedule.media_name + prog['access_id'].to_s + prog['latest_episode_id'].to_s

                schedule.from_time = now + 60
                schedule.save_since_finger_print_not_exist

              end
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

    end
  end
end

