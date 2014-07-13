
module Bromo

  class Config

    @@config = {
      rc_path: "~/.bromorc.rb",
      data_dir: "~/.bromo",
      sqlite_name: "data.sql",
      host: 'localhost', # sinatra set host
      port: '7970', # sinatra set port
      debug: false,
    }

    def self.configure(&block)
      block.call(self) if block_given?
      self
    end

    def self.check_path

      # check rc
      rc_path = ENV['BROMO_CONFIG_PATH'] || @@config[:rc_path]
      rc_path = File.expand_path rc_path
      if File.exist? rc_path
        self.rc_path = rc_path
      else
        self.rc_path = ''
      end

      # check dir
      _data_dir = ENV['BROMO_DATA_DIR'] || @@config[:data_dir]
      FileUtils.mkdir_p(_data_dir) if !File.exist?(_data_dir)
      self.data_dir = File.expand_path _data_dir

      # db
      # db = SQLite3::Database.new(File.join(data_dir, @@config[:sqlite_name]))

      true
    end

    def self.check_config
      true
    end

    @@broadcaster_names = []
    def self.use(broadcaster_name)
      broadcaster_name = broadcaster_name.to_s

      if(broadcaster_name == 'all')
        # @@broadcaster_names = %w/ag radiko/ #FIXME
        @@broadcaster_names = %w/radiko/ #FIXME
      else
        @@broadcaster_names.push broadcaster_name
      end

      @@broadcaster_names.uniq!
    end
    def self.broadcaster_names
      @@broadcaster_names
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

  end

end
