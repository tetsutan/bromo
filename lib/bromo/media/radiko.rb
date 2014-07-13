module Bromo
  module Media
    class Radiko
      include Base

      realtime :true
      recording_delay_for_realtime 20

      def clean_db
        clear_before(:two_weeks)
      end

      def update_db
        # weekly
        area_id = "JP13" # default: Tokyo
        now = Time.now.to_i
        get_station_ids_with_url("http://radiko.jp/v2/station/list/#{area_id}.xml?_=#{now}").each do |station_id|
          update_weekly_program_with_url("http://radiko.jp/v2/api/program/station/weekly?station_id=#{station_id}&_=#{now}")
        end
      end

      def get_station_ids_with_url(url)
        open(url) do |f|
          doc = Nokogiri::XML(f.read)
          return doc.xpath('//stations/station/id').map do |s|
            s.text
          end
        end
      end

      def update_weekly_program_with_url(url)
        open(url) do |f|
          doc = Nokogiri::XML(f.read)
          doc.xpath('//radiko/stations/station').each do |s|
            ch_id = s['id']
            s.xpath('scd/progs/prog').each do |prog|

              # Model::Schedule.
              schedule = Model::Schedule.new
              schedule.module_name = self.name
              schedule.channel_name = ch_id
              schedule.title = prog.xpath('title').text
              schedule.description = prog.xpath('info').text
              schedule.from_time = time_parser(prog['ft']).to_i
              schedule.to_time = time_parser(prog['to']).to_i

              schedule.finger_print = schedule.module_name + schedule.channel_name + schedule.from_time.to_s

              schedule.save_since_finger_print_not_exist


            end

          end

        end
      end

      def time_parser(str)
        # 20130707050000 = 2013/07/07 05:00:00

        y = str[0,4]
        m = str[4,2]
        d = str[6,2]
        h = str[8,2]
        i = str[10,2]
        s = str[12,2]

        time = Time.mktime(y,m,d,h,i,s,0)
        time
      end

      def record(schedule)

        # internal setting
        _retry_count = 20
        _tempfile_name = "original_data"

        time_to_left = schedule.time_to_left
        logger.debug("recroding start #{schedule.title}, wait = #{time_to_left}")
        sleep time_to_left if time_to_left > 0

        tempfile = Tempfile::new(_tempfile_name)
        logger.debug("radiko:#{schedule.id}: record to #{tempfile.path}")

        if realtime? && recording_delay_for_realtime > 0
          sleep recording_delay_for_realtime
        end

        duration = schedule.to_time - schedule.from_time
        count = 0
        loop do
          break if _record_to_path(tempfile.path, schedule.channel_name, duration)
          logger.debug("radiko:#{schedule.id}: retry #{count}")
          duration = self.to_time - Time.now.to_i # update duration
          count += 1
          return false if count > _retry_count
        end

        rec_filepath = File.join(Bromo::Config.data_dir,
                                 generate_filename(schedule.title))
        transcode_to_mpx(tempfile.path, rec_filepath)

        # remove old file
        tempfile.close(true)

        schedule.file_path = tempfile.path
        return true
      end

      def _record_to_path(filepath, channel,duration)
        playerurl="http://radiko.jp/player/swf/player_3.0.0.01.swf"
        rtmpdump="/usr/local/bin/rtmpdump"
        
        # use open-uri to get fileobject
        retry_cont = 0
        begin
          open(playerurl) do |f|
            swf = SwfRuby::SwfDumper.new
            swf.open(f)
          
            keyfile = nil
            swf.tags.each do |t|
              if t.character_id == 14
                keyfile = t
              end
            end
          
            if !keyfile
              raise "No keyfile on #{playerurl}"
              exit
            end
          
          
            ## get auth1_fms
            uri = URI.parse('https://radiko.jp/v2/api/auth1_fms')
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            hash = {}
            http.start do |h|
              header = {
                'pragma' => 'no-cache',
                'X-Radiko-App' => 'pc_1',
                'X-Radiko-App-Version' => '2.0.1',
                'X-Radiko-User' => 'test-stream',
                'X-Radiko-Device' => 'pc',
              }
              body = "\r\n"
              begin
                res = h.post(uri.path, body, header)
              rescue Errno::ETIMEDOUT => exc
                Bromo.debug "#{object_id} ERROR: #{exc.message}"
                Bromo.debug "#{object_id} Can't open #{uri.path} F#{__FILE__} L#{__LINE__}"
                next
              end
          
              flatten = res.body.split("\r\n").map{|v| v.split("=")}.flatten
              if(flatten.size % 2 != 0)
                flatten.push(nil)
              end
          
              hash = Hash[*flatten]
          
              # key to downcase
              new_hash = {}
              hash.each do |k,v|
                new_hash[k.downcase] = v
              end
              hash = new_hash
          
              Bromo.debug "auth1 res headers"
              Bromo.debug hash
            end
          
          
            authtoken = hash['x-radiko-authtoken']
            offset = hash['x-radiko-keyoffset'].to_i
            length = hash['x-radiko-keylength'].to_i
          
            Bromo.debug "authtoken = #{authtoken}"
            Bromo.debug "offset = #{offset}"
            Bromo.debug "length = #{length}"
          
            bin = keyfile.data[offset+6, length] # FIXME why 6
            Bromo.debug "bin = #{bin.unpack('H*')}"
          
            partialkey =  Base64.encode64(bin)
            Bromo.debug "partialkey = #{partialkey}"
          
          
            ## get auth2_fms
            uri = URI.parse('https://radiko.jp/v2/api/auth2_fms')
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            hash = {}
            http.start do |h|
              header = {
                'pragma' => 'no-cache',
                'X-Radiko-App' => 'pc_1',
                'X-Radiko-App-Version' => '2.0.1',
                'X-Radiko-User' => 'test-stream',
                'X-Radiko-Device' => 'pc',
                'X-Radiko-Authtoken' => authtoken,
                'X-Radiko-Partialkey' =>  partialkey,
              }
              body = "\r\n"
              res = h.post(uri.path, body, header)
          
              Bromo.debug res
              Bromo.debug res.header
              Bromo.debug res.body
              if res.code == "200"
                flatten = res.body.split("\r\n").map{|v| v.split("=")}.flatten
                if(flatten.size % 2 != 0)
                  flatten.push(nil)
                end
          
                hash = Hash[*flatten]
          
                # key to downcase
                new_hash = {}
                hash.each do |k,v|
                  new_hash[k.downcase] = v
                end
                hash = new_hash
          
                Bromo.debug "auth2 res headers"
                Bromo.debug hash
              end
          
            end
          
            if !hash.empty?
          
              begin
                open("http://radiko.jp/v2/station/stream/#{channel}.xml") do |channel_file|

                  doc = Nokogiri::XML(channel_file.read)
          
                  stream_url = doc.xpath('/url/item[1]').text
                  stream_uri = URI.parse(stream_url)
                  Bromo.debug stream_url
          
                  rtmp_path = "#{stream_uri.scheme}://#{stream_uri.host}"
                  app = File.dirname(stream_uri.path)
                  app = app[1,app.size]
                  playpath = File.basename(stream_uri.path)

                  rand_name = authtoken + rand(1000).to_s
                  # t = Time.now
                  # filepath = File.join(::Bromo.data_dir, t.strftime("%Y%m%d_%H%M_") + authtoken)
          

                  cmd = "rtmpdump \
                    -r #{rtmp_path} \
                    --app #{app} \
                    --playpath #{playpath} \
                    -W #{playerurl} \
                    -C S:'' -C S:'' -C S:'' -C S:#{authtoken} \
                    --live \
                    --stop #{duration} \
                    --flv '#{filepath}'"

                  Bromo.debug cmd.split(" ")
                  `#{cmd}`
                  exit_code = $?
                  Bromo.debug "#{object_id} recording done (radiko) with code = #{exit_code}"

                  return exit_code.success?
                end
              rescue => e
                # 50X系のエラーだと思うのでリトライさせる？
                Bromo.debug e.message
                Bromo.debug "Cant open stream channel"
              end

          
          
          
            end
          
          
          end
        rescue Errno::ECONNRESET => e
          retry_cont+=1
          if retry_cont < 10
            retry
          else
            Bromo.debug e.message
            Bromo.debug "retry count over 10"
          end
        end

      end


    end

  end
end


