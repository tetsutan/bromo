
module Bromo

  class Config

    @@production = ENV['RACK_ENV'] == 'production'
    @@dot_bromo = @@production ? ".bromo" : ".bromo.development"

    @@config = {
      rc_path: "~/.bromorc.rb",
      data_dir: "~/#{@@dot_bromo}/data",
      image_dir: "~/#{@@dot_bromo}/image",
      log_dir: "~/#{@@dot_bromo}/log",
      host: nil, # sinatra set host
      port: @@production ? '7970' : '3000', # sinatra set port
      debug: !@@production,
      podcast_title_prefix: 'Bromo: ',
      podcast_link: nil, # same as host if nil
      rtmpdump: "rtmpdump",
      ffmpeg: "ffmpeg",
    }

    def self.configure(&block)
      if @call_configure
        block.call(self) if block_given?
      end
      self
    end

    def self.load_config
      @call_configure = true
      load Bromo::Config.rc_path if Bromo::Config.check_path
    end

    def self.reload_config
      @call_configure = false
      load Bromo::Config.rc_path
    end

    def self.check_path

      # check rc
      if !File.exist? self.rc_path
        return false
      end

      # check dir
      self.data_dir
      self.image_dir
      self.log_dir

      self.check_config

      true
    end

    def self.check_config

      status, stdout, stderr = systemu("#{self.rtmpdump} -h")
      if status != 0
        raise "No rtmpdump"
      end

      status, stdout, stderr = systemu("#{self.ffmpeg} -h")
      if status != 0
        raise "No ffmpeg"
      end
      FFMPEG.ffmpeg_binary = self.ffmpeg

      true
    end

    @@media_names = []
    def self.use(media_name)
      media_name = media_name.to_s

      if(media_name == 'all')
        const = Media.constants.dup
        const.delete(:Base)
        @@media_names = const.map(&:to_s).map(&:underscore)
      else
        @@media_names.push media_name
      end

      @@media_names.uniq!
    end
    def self.media_names
      @@media_names
    end


    def self.method_missing(method, value = nil, *args, &block)
      if value
        if method.to_s[-1] == "="
          method = method.to_s
          method = method[0,method.size-1]
          method = method.to_sym
        end
        raise "No config key of #{method}" unless @@config.keys.include?(method)
        @@config[method] = value
      else
        raise "No config key of #{method}" unless @@config.keys.include?(method)
        @@config[method]
      end
    end

    def self.basic_authentication_env
      [ENV['BASIC_AUTH_USERNAME'], ENV['BASIC_AUTH_PASSWORD']]
    end


    @@data_dir = nil
    def self.data_dir
      return @@data_dir if @@data_dir

      _data_dir = @@config[:data_dir]
      _data_dir = File.expand_path _data_dir
      FileUtils.mkdir_p(_data_dir) if !File.exist?(_data_dir)
      @@data_dir = _data_dir
      @@data_dir
    end

    @@image_dir = nil
    def self.image_dir
      return @@image_dir if @@image_dir

      _image_dir = @@config[:image_dir]
      _image_dir = File.expand_path _image_dir
      FileUtils.mkdir_p(_image_dir) if !File.exist?(_image_dir)
      @@image_dir = _image_dir
      @@image_dir
    end

    @@log_dir = nil
    def self.log_dir
      return @@log_dir if @@log_dir

      _log_dir = @@config[:log_dir]
      _log_dir = File.expand_path _log_dir
      FileUtils.mkdir_p(_log_dir) if !File.exist?(_log_dir)
      @@log_dir = _log_dir
      @@log_dir
    end

    @@rc_path = nil
    def self.rc_path
      return @@rc_path if @@rc_path

      _rc_path = ENV['BROMO_CONFIG_PATH'] || @@config[:rc_path]
      @@rc_path = File.expand_path _rc_path
      @@rc_path
    end


  end

end
