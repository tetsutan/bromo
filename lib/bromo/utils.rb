
require 'bromo/utils/logger'
require 'bromo/utils/exsleep'
require 'bromo/utils/date'
require 'bromo/utils/debug'

require 'unf'

module Bromo
  module Utils
    def self.save_image(url)

      if url.start_with?('http')
        # binary
        ext = File.extname(URI.parse(url).path)
        name = Digest::SHA1.hexdigest(url)
        file_name = "#{name}#{ext}"
        file_path = File.join(Config.image_dir, file_name)

        if !File.exist?(file_path)
          begin
            open(url) do |f_image|
              open(File.join(Config.image_dir, file_name), "w") do |f_dest|
                f_dest.write(f_image.read)
              end
            end
          rescue
            return nil
          end
        end

        return file_name
      end
    end

    @@norm = UNF::Normalizer.new
    def self.normalize_search_text(text)
      @@norm.normalize(text,:nfkc)
    end

    def self.shell_filepathable(str)
      str.gsub(/[ \/\\\"\':?=\.]/,'').gsub(/[[:cntrl:]]/,"")
    end

    def self.sanitize(str, remove_control=true)
      str = Nokogiri::HTML(str.to_s).text
      remove_control ? str.gsub(/[[:cntrl:]]/,"") : str
    end

    # for debug
    def self.save_to_file(name, data)
      return if !Bromo.debug?

      time_str = Time.now.strftime("%Y%m%d_%H%M%S")
      path = File.join(Config.log_dir, "#{time_str}_#{shell_filepathable(name)}")
      open(path, "w") do |f|
        f.write data
      end

    end

  end
end

