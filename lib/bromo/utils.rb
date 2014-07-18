
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
        ext = url.split(".").last
        name = Digest::SHA1.hexdigest(url)
        file_name = "#{name}.#{ext}"
        file_path = File.join(Config.image_dir, file_name)

        if !File.exist?(file_path)
          open(url) do |f_image|
            open(File.join(Config.image_dir, file_name), "w") do |f_dest|
              f_dest.write(f_image.read)
            end
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
      str.gsub(/[ \/\\\"\']/,'').gsub(/[[:cntrl:]]/,"")
    end

    def self.sanitize(str)
      Nokogiri::HTML(str.to_s).text.gsub(/[[:cntrl:]]/,"")

    end


  end
end

