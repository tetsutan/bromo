require 'base64'

module Bromo
  module Recorder
    class M3u

      attr_accessor :url
      attr_accessor :realtime
      attr_accessor :request_options
      attr_accessor :m3us
      attr_accessor :downloaded_inf_ids
      attr_accessor :m3uTmpDir

      def initialize(url, realtime = false, request_options = {})
        self.url = url
        self.realtime = realtime
        self.request_options = request_options

        self.m3us = {
          # url: obj
        }
        self.downloaded_inf_ids = []

        # tmpdir
        self.m3uTmpDir = Dir.mktmpdir("m3u-" + Utils.shell_filepathable(url))

      end

      def record(to_time=0)
        rec(url, to_time)
      end

      def rec(url, to_time=0)

        base_url = File.dirname(url)

        target_duration = 9
        encription_option = nil
        Bromo.debug "#{object_id} from(now): #{Time.now.to_i} to: #{to_time.to_i}"
        Bromo.debug "#{object_id} realtime = #{realtime}"

        retry_count = 0
        while !realtime || Time.now.to_i < to_time.to_i
          Bromo.debug "#{object_id} recording.. url = #{url}"

          # #EXTM3U
          # #EXT-X-TARGETDURATION:9
          # #EXT-X-MEDIA-SEQUENCE:76878
          # #EXTINF:9,
          # http://ic-www.uniqueradio.jp/iphone/3G/Seg_072513_043752_384/3G_072513_043752_76878.ts
          # #EXTINF:9,
          # http://ic-www.uniqueradio.jp/iphone/3G/Seg_072513_043752_384/3G_072513_043752_76879.ts

          begin
            Utils.cookie_with(url, request_options) do |res, cookie|
              inf = {}
              Bromo.debug "#{object_id} m3u cookie = #{cookie}"
              if cookie
                _r = self.request_options
                _r["Cookie"] = cookie
                self.request_options = _r
              end
              Bromo.debug "#{object_id} m3u cookie2= #{self.request_options['Cookie']}"
              res.body.each_line do |line|

                if line.match(/^#/)
                  if line.match(/^#EXT-X-TARGETDURATION:([0-9]*)$/)
                    # update target duration
                    target_duration = $1

                  # ohsama
                  # #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=235000,RESOLUTION=400x224
                  # #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=575000,RESOLUTION=640x360
                  elsif line.match(/^#EXT-X-STREAM-INF:(.*)$/)
                    $1.split(",").map(&:strip).each do |kv|
                      key, val = kv.split("=")
                      inf[key] = val
                    end
                  elsif line.match(/^#EXT-X-KEY:(.*)$/)
                    #EXT-X-KEY:METHOD=AES-128,URI="https://vms-api.hibiki-radio.jp/api/v1/videos/datakey?kid=M1vnLF1sFUNrPytNIMv9tg%3D%3D",IV=0x9a1f051596f56bf9b548ff1f7245c196

                    Bromo.debug "#{object_id} m3u #{line}"
                    encription_option = Utils.query_to_hash($1, ",")

                  end
                else
                  m3u_url = line.chomp
                  if !m3u_url.match(/^http/)
                    # no schema
                    m3u_url = File.join(base_url,m3u_url)
                  end

                  inf_id = inf["PROGRAM-ID"] || nil
                  if !self.m3us[m3u_url] && !self.downloaded_inf_ids.include?(inf_id)
                    if m3u_url.match(/m3u8$/)
                      _m3u = M3u.new(m3u_url, realtime, request_options)
                      self.m3us[m3u_url] = _m3u.record(to_time)
                    else
                      self.m3us[m3u_url] = M3uDownloader.new(m3u_url, request_options, m3uTmpDir)
                    end
                    self.downloaded_inf_ids.push(inf_id) if inf_id
                  end

                  inf = {} # reset inf
                end

              end
            end
          rescue => e
            Bromo.debug e.message
            puts e.backtrace
            Bromo.debug "#{object_id} Can't open url F#{__FILE__} L#{__LINE__}"
            if retry_count > 20
              block.call if block_given?
              return
            end
            retry_count += 1
          end

          # Bromo.debug "self.m3us size = #{self.m3us.size}"
          self.m3us.each do |url, m3u|
            m3u.download if m3u.is_a?(M3uDownloader) && !m3u.downloaded?
          end

          # Bromo.debug "sleep target_duration of #{target_duration}"
          break if !realtime
          sleep target_duration
        end

        Bromo.debug "#{object_id} done"

        # concat
        # data = self.m3us.values.map{|m3u| m3u.data }.join
        _m3us = []
        _decrypter = nil
        if encription_option
          _decrypter = Decrypter.new(request_options, encription_option)
        end

        self.m3us.each do |key, m3u|
          data = if m3u.is_a? M3uDownloader
            m3u.data
          else
            m3u
          end

          if _decrypter
            # Utils.save_to_file("m3u_ts_#{key}.ts", data)
            data = _decrypter.decrypt(data)
            # assert("hoge")
          end

          _m3us.push(data)
        end

        data = _m3us.join
        Bromo.debug "#{object_id} M3u temp dir = #{self.m3uTmpDir}"
        FileUtils.remove_entry_secure self.m3uTmpDir
        data

      end

      class Decrypter
        attr_accessor :cipher
        def initialize(request_options, encription_option)
          if encription_option["METHOD"] == "AES-128"
            url = encription_option["URI"]
            Bromo.debug "#{object_id} M3u Encript: url = #{url}"
            Bromo.debug "#{object_id} M3u Encript: cookie = #{request_options['Cookie']}"
            Utils.cookie_with(url, request_options) do |res, cookie|
              key = res.body
              iv = encription_option["IV"]
              if iv[0,2] == "0x"
                # iv = [ iv[2,iv.size-2] ].pack("H*")
                iv = iv[2,iv.size-2].unpack('a2'*16).map{ |x| x.hex }.pack('C'*16)
              else
                assert("Unsupported IV binary = " + iv)
              end

              # Bromo.debug "#{object_id} M3u Decript: key = #{key}"
              # Bromo.debug "#{object_id} M3u Decript: iv = #{iv}"
              Bromo.debug "#{object_id} M3u Decript: base64 key = #{Base64.encode64(key)}"
              Bromo.debug "#{object_id} M3u Decript: base64 iv = #{Base64.encode64(iv)}"

              s = OpenSSL::Cipher.new('aes-128-cbc')
              s.key = key
              s.iv = iv
              s.decrypt
              self.cipher = s
            end

          else
            raise "No enciption method found #{encription_option}"
          end
        end

        def decrypt(data)
          cipher.update(data) + cipher.final
        end

      end

      def decript(data, request_options, encription_option)
      end


      class M3uDownloader

        attr_accessor :url
        attr_accessor :request_options
        attr_accessor :use_file_for_download , :download_filepath
        attr_accessor :m3uTmpDir

        def initialize(_url, request_options = {}, m3uTmpDir = Dir.mktmpdir("m3u-" + Utils.shell_filepathable(_url)))
          self.url = _url
          self.request_options = request_options
          self.use_file_for_download = true
          self.m3uTmpDir = m3uTmpDir
          if self.use_file_for_download
            self.download_filepath = File.join(m3uTmpDir, Utils.shell_filepathable(_url))
          end
        end

        def download
          if self.url
            begin
              Utils.cookie_with(self.url, request_options) do |res, cookie|
                _data = res.body
                if self.use_file_for_download
                  open(self.download_filepath, "w") do |f|
                    f.write(_data)
                  end
                else
                  @data = _data
                end
              end
            rescue => e
              Bromo.debug e.message
              Bromo.debug "#{object_id} Can't open #{self.url} F#{__FILE__} L#{__LINE__}"
              return
            end
          end
        end

        def downloaded?
          if self.use_file_for_download
            FileTest.size?(self.download_filepath)
          else
            !!@data
          end
        end

        def data
          if self.use_file_for_download
            f = open(self.download_filepath)
            data = f.read
            f.close
            data
          else
            @data
          end
        end

      end

    end

  end
end

