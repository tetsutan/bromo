require 'active_support'
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

      module Setting
        module ClassMethods
          @@realtime = false
          @@recording_delay_for_realtime = 0
          def realtime(val)
            @@realtime = !!val
          end
          def recording_delay_for_realtime(val)
            @@recording_delay_for_realtime = val
          end
        end

        def realtime?
          @@realtime
        end
        def recording_delay_for_realtime
          @@recording_delay_for_realtime
        end
      end


      extend ActiveSupport::Concern
      include Utils::Logger
      include Setting

      included do
        extend ClassMethods
      end

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
      def record(*args)
        raise "do inherit record!"
      end

    end
  end
end
