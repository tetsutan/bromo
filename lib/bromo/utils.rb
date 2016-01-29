
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
      str.gsub(/[ \/\\\"\':?=]/,'').gsub(/[[:cntrl:]]/,"")
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


    FIREFOX_HEADERS = {
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:23.0) Gecko/20100101 Firefox/23.0",
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "Accept-Language" => "ja,en-us;q=0.7,en;q=0.3",
      "Connection" => "keep-alive",
      "Cache-Control" => "max-age=0"
    }
    def self.cookie_with(url, options = {})

      uri = URI.parse(url)

      https = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == "https"
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      https.start do |http|

        request = Net::HTTP::Get.new(uri.request_uri)

        # FIREFOX_HEADERS.each do |k,v|
        #   request[k] = v
        # end
        request['Host'] = uri.host
        # request['Cookie'] = cookie if cookie
        # request['Referer'] = referer if referer
        options.each do |k,v|
          request[k] = v
        end

        begin
          response = http.request(request)
        rescue Errno::ETIMEDOUT => exc
          Bromo.debug "#{object_id} ERROR: #{exc.message}"
          Bromo.debug "#{object_id} Can't open #{url} F#{__FILE__} L#{__LINE__}"
          return false
        end

        cookie = response.get_fields("Set-Cookie") if !cookie
        yield(response, cookie)
      end

    end

    def self.query_to_hash(str, first_divider="&", second_divider="=")
      str.split(first_divider).inject({}) do |res, val|
        k,v = val.split(second_divider, 2)

        if v[0] == '"' && v[v.size-1] == '"'
          v = v[1, v.size - 2]
        end

        v ? res.merge({k => v}) : res.merge({k => true})
      end
    end

  end
end

