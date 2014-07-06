require 'open-uri'
require 'nokogiri'
require 'swf_ruby'
require 'base64'
require 'streamio-ffmpeg'
require 'tempfile'
require 'pp'
require 'fileutils'

module Bromo
  module Media
    module Base

      def name
        self.class.name.split("::").last.downcase
      end

      def refresh_time_since
        Utils::Date.next("500")
      end

      def clear_before(key)
        case key
        when :two_weeks
          # TODO create method to clear old schedule on database
        end
      end

      def update_schedule
        clean_db
        update_db
      end

      # inheritance methods
      def clean_db
        raise "do inherit clean_db!"
      end
      def update_db
        raise "do inherit update_db!"
      end


    end
  end
end
