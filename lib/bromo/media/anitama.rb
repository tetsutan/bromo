require 'nokogiri'

module Bromo
  module Media
    class Anitama
      include Base

      # reserved_1: book_id

      HEADERS = {
        "Host" => "www.weeeef.com",
        "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:23.0) Gecko/20100101 Firefox/23.0",
        # "User-Agent" => "Mozilla/5.0 (iPhone; CPU iPhone OS 7_1 like Mac OS X) AppleWebKit/537.51.2 (KHTML, like Gecko) Version/7.0 Mobile/11D167 Safari/9537.53",
        "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language" => "ja,en-us;q=0.7,en;q=0.3",
        # "Accept-Encoding" => "gzip, deflate",
        # "Referer" => "http://www.animate.tv/radio/details.php?id=muromisan",
        # "Cookie" => "__utma=130647903.1882911751.1372226761.1377686703.1377690672.22; __utmz=130647903.1377118985.16.10.utmccn=(organic)|utmcsr=google|utmctr=|utmcmd=organic; pal=RPGrimoire%2CRPtsumashio%2CNP1377501378%2CRPmuromisan; atv=48701ec71f69f6155e468f325f8f0f15; __utmc=130647903; __utmb=130647903",
        "Connection" => "keep-alive",
        "Cache-Control" => "max-age=0"
        }

      def update_db

        now = Time.now.to_i
        cookie = get_cookie

        url = "http://www.weeeef.com/weeeef001/BookServlet"
        res = get_response(url, cookie, COMMAND_URL)

        Utils.save_to_file("Anitama_have_checked_updating_schedule", res)

        doc = Nokogiri::XML(res)

        return false if doc.children.empty?

        doc.xpath("//Books/Book").each do |book|

          title = book.attribute('label').text
          updatetime = book.attribute('updateTime').text
          book_id = book.attribute('id').text # contens ID in program
          contents_id = book.attribute('contentsId').text # program ID


          # Model::Schedule.
          schedule = Model::Schedule.new
          schedule.media_name = self.name
          schedule.channel_name = ""
          schedule.title = Utils.sanitize(title)
          schedule.description = updatetime

          schedule.from_time = 0
          schedule.to_time = 0

          schedule.reserved_1 = book_id

          schedule.finger_print = schedule.media_name + book_id + contents_id

          schedule.from_time = now + 60
          schedule.save_since_finger_print_not_exist

        end

        true
      end

      def record(schedule)
        cookie = get_cookie
        referer = COMMAND_URL
        url = "http://www.weeeef.com/weeeef001/BookXmlGet?BookId=#{schedule.reserved_1}"
        res = get_response(url, cookie, referer)
        doc = Nokogiri::XML(res)

        nodes = doc.xpath('//Node')
        raise if nodes.size < 4

        node_id_obj = nodes[2].css('Id').first
        node_title_obj = nodes[2].css('Title')[1]

        if !node_id_obj || !node_title_obj
          return false
        end

        node_id = node_id_obj.content
        node_title = node_title_obj.content

        url = "http://www.weeeef.com/weeeef001/OriginalGet"
        uri = URI.parse(url)
        Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Post.new(uri.request_uri)
          HEADERS.each do |k,v|
            request[k] = v
          end
          request['Cookie'] = cookie
          request['Referer'] = referer
          # type=S&nodeId=C0000005B0000326P0000001R0000001
          request.set_form_data({type:"S", nodeId: node_id})
          begin
            response = http.request(request)
          rescue Errno::ETIMEDOUT => exc
            Bromo.debug "#{object_id} ERROR: #{exc.message}"
            Bromo.debug "#{object_id} Can't open #{file_url} F#{__FILE__} L#{__LINE__}"
            return false
          end

          data = response.body
          if data && data.size > 0
            file_name = generate_filename(schedule.title, schedule.video?)
            save_tempfile_and_transcode_to_data_dir(data, file_name)
            return file_name
          end

        end

        return false

      end


      COMMAND_URL = "http://www.weeeef.com/weeeef001/Transition?command=top&group=G0000049"
      def get_cookie

        url = COMMAND_URL
        uri = URI.parse(url)
        Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Get.new(uri.request_uri)
          HEADERS.each do |k,v|
            request[k] = v
          end
          begin
            response = http.request(request)
          rescue Errno::ETIMEDOUT => exc
            Bromo.debug "#{object_id} ERROR: #{exc.message}"
            Bromo.debug "#{object_id} Can't open #{file_url} F#{__FILE__} L#{__LINE__}"
            return false
          end

          return response.get_fields("Set-Cookie")
        end

      end

      def get_response(url, cookie, referer)
        uri = URI.parse(url)
        Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Get.new(uri.request_uri)

          HEADERS.each do |k,v|
            request[k] = v
          end
          request['Cookie'] = cookie
          request['Referer'] = referer


          begin
            response = http.request(request)
          rescue Errno::ETIMEDOUT => exc
            Bromo.debug "#{object_id} ERROR: #{exc.message}"
            Bromo.debug "#{object_id} Can't open #{playpath} F#{__FILE__} L#{__LINE__}"
            return false
          end

          return response.body
        end

      end


    end
  end
end



