module Bromo
  module Recorder
    class M3u

      attr_accessor :url
      attr_accessor :realtime
      attr_accessor :m3us
      attr_accessor :downloaded_inf_ids

      def initialize(url, realtime = false)
        self.url = url
        self.realtime = realtime

        self.m3us = {
          # url: obj
        }
        self.downloaded_inf_ids = []
      end

      def record(to_time=0)
        rec(url, to_time)
      end

      def rec(url, to_time=0)

        base_url = File.dirname(url)

        target_duration = 9
        ts_set = Set.new
        Bromo.debug "#{object_id} from(now): #{Time.now.to_i} to: #{to_time.to_i}"
        Bromo.debug "#{object_id} realtime = #{realtime}"

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
            open(url) do |f|
              inf = {}
              f.each do |line|

                if line.match(/^#/)
                  if line.match(/^#EXT-X-TARGETDURATION:([0-9]*)$/)
                    # update target duration
                    target_duration = $1
                  end

                  # ohsama
                  # #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=235000,RESOLUTION=400x224
                  # #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=575000,RESOLUTION=640x360
                  if line.match(/^#EXT-X-STREAM-INF:(.*)$/)
                    $1.split(",").map(&:strip).each do |kv|
                      key, val = kv.split("=")
                      inf[key] = val
                    end
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
                      _m3u = M3u.new(m3u_url, realtime)
                      self.m3us[m3u_url] = _m3u.record(to_time)
                    else
                      self.m3us[m3u_url] = M3uDownloader.new(m3u_url)
                    end
                    self.downloaded_inf_ids.push(inf_id) if inf_id
                  end

                  inf = {} # reset inf
                end

              end
            end
          rescue => e
            Bromo.debug e.backtrace
            Bromo.debug "#{object_id} Can't open url F#{__FILE__} L#{__LINE__}"
            block.call if block_given?
            return
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
        self.m3us.each do |key, m3u|
          if m3u.is_a? M3uDownloader
            _m3us.push(m3u.data)
          else
            _m3us.push(m3u)
          end
        end

        # close m3u
        self.m3us.each do |key, m3u|
          m3u.close if m3u.is_a? M3uDownloader
        end

        return _m3us.join
      end

      class M3uDownloader

        attr_accessor :url
        attr_accessor :use_file_for_download, :downloaded_file

        def initialize(_url)
          self.url = _url
          self.use_file_for_download = true
          if self.use_file_for_download
            self.downloaded_file = Tempfile::new('downloaded_cache_')
          end
        end

        def download
          if self.url
            begin
              open(self.url) do |f|
                _data = f.read
                if self.use_file_for_download
                  self.downloaded_file.write(_data)
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
            self.downloaded_file.size > 0
          else
            !!@data
          end
        end

        def data
          if self.use_file_for_download
            self.downloaded_file.rewind
            self.downloaded_file.read
          else
            @data
          end
        end

        def close
          self.downloaded_file.close if self.use_file_for_download && self.downloaded_file
        end

      end

    end

  end
end

